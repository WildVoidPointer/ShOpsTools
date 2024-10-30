#!/bin/bash


MYSQL_PKG_PATH='mysql-5.7.44-linux-glibc2.12-x86_64.tar.gz'

MYSQL_PKG_DIR='mysql-5.7.44-linux-glibc2.12-x86_64'

MYSQL_INSTALL_PATH='/usr/local/mysql57'


function set_error_log {
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "\033[31m$timestamp - ERROR - $1\n\033[0m"
    exit 1
}


function set_info_log {
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "\033[32m$timestamp - INFO - $1\n\033[0m"
}


function is_exist_of_resource {
    if [ -e "$1" ]
    then
        set_info_log "$1 is found"
        return 0
    else
        set_error_log "$1 is not found"
        return 1
    fi
}


function is_exist_of_user {
    if id "$1" &>/dev/null 
    then
        set_info_log "$1 is found"
        return 0
    else
        set_error_log "$1 is not found"
        return 1
    fi
}


function is_exist_of_group {
    if getent group "$1" &>/dev/null
    then
        set_info_log "$1 is found"
        return 0
    else
        set_error_log "$1 is not found"
        return 1
    fi
}


function set_the_pkg_path {
    if ! is_exist_of_resource "$MYSQL_PKG_PATH"
    then
        exit 1
    fi

    sudo tar -zxvf "$MYSQL_PKG_PATH" &> /dev/null

    if ! is_exist_of_resource "$MYSQL_PKG_DIR"
    then
        exit 1
    fi

    sudo cp -r "$MYSQL_PKG_DIR" "$MYSQL_INSTALL_PATH"

    if ! is_exist_of_resource "$MYSQL_INSTALL_PATH"
    then
        exit 1
    fi

}


function install_dep_of_mysql {
    sudo apt update
    sudo apt install -y libncurses5
    sudo apt install -y libaio1

    if apt list --installed | grep -q libncurses5
    then
        set_info_log "libncurses5 install successfully"
    else
        set_error_log "libncurses5 installation failure"
    fi

    if apt list --installed | grep -q libaio1
    then
        set_info_log "libaio1 install successfully"
    else
        set_error_log "libaio1 installation failure"
    fi
}



function set_mod_and_user_of_mysql {
    sudo groupadd mysql
    sudo useradd -r -g mysql -s /bin/false mysql
    if is_exist_of_user 'mysql' && is_exist_of_group 'mysql'
    then
        set_info_log "user mysql and group mysql create successfully"
    else
        exit 2
    fi

    cd "$MYSQL_INSTALL_PATH"

    sudo mkdir data

    if ! is_exist_of_resource data
    then
        exit 1
    fi

    sudo chown mysql:mysql data

    sudo chmod 750 data
}


function start_for_mysql_server {
    sudo ./bin/mysqld --initialize --user=mysql \
        --lc-messages-dir=/usr/local/mysql57/share/ \
        --datadir=/usr/local/mysql57/data/ &> initializeError.log

    sudo bin/mysql_ssl_rsa_setup --datadir=/usr/local/mysql57/data

    bin/mysqld_safe --user=mysql &

    sudo cp support-files/mysql.server /etc/init.d/mysql.server

    sudo /etc/init.d/mysql.server start

    echo "export PATH=$PATH:$MYSQL_INSTALL_PATH/bin" >> /etc/profile
}


set_info_log "start intsall mysql57 process"

install_dep_of_mysql

set_the_pkg_path

set_mod_and_user_of_mysql

start_for_mysql_server
