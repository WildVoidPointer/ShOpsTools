#!/bin/bash

MYSQL_PKG_PATH='mysql-5.7.44-linux-glibc2.12-x86_64.tar.gz'

MYSQL_INSTALL_PATH='/usr/local/bin/mysql57'

MYSQL_INITIALIZE_LOG_PATH='/mysql_initialize_error.log'

MYSQL_ENV_CONF_PATH='/etc/profile'

MYSQL_DATA_DIR_PATH="${MYSQL_INSTALL_PATH}/data"


function set_mysql_install_error_log {
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "\033[31m$timestamp - ERROR - $1\n\033[0m"
    exit 1
}


function set_mysql_install_info_log {
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "\033[32m$timestamp - INFO - $1\n\033[0m"
}


function is_exist_of_mysql_resource {
    if [ -e "$1" ]
    then
        set_mysql_install_info_log "$1 is found"
        return 0
    else
        set_mysql_install_error_log "$1 is not found"
        return 1
    fi
}


function is_exist_of_mysql_user {
    if id "$1" &>/dev/null 
    then
        set_mysql_install_info_log "$1 is found"
        return 0
    else
        set_mysql_install_error_log "$1 is not found"
        return 1
    fi
}


function is_exist_of_mysql_group {
    if getent group "$1" &>/dev/null
    then
        set_mysql_install_info_log "$1 is found"
        return 0
    else
        set_mysql_install_error_log "$1 is not found"
        return 1
    fi
}


function install_mysql_binary_pkg {
    if ! is_exist_of_mysql_resource "$MYSQL_PKG_PATH"
    then
        set_mysql_install_error_log 'MySQL Package does not exist'
        exit 1
    fi

    sudo mkdir -p "$MYSQL_INSTALL_PATH"
    sudo tar -zxvf "$MYSQL_PKG_PATH" -C "$MYSQL_INSTALL_PATH" --strip-components=1 &> /dev/null

    if ! is_exist_of_mysql_resource "$MYSQL_INSTALL_PATH"
    then
        set_mysql_install_error_log 'The mysql resource does not exist'
        exit 1
    fi

}


function install_dependancies_of_mysql {
    sudo apt-get update
    sudo apt-get install -y libncurses5
    sudo apt-get install -y libaio1

    if dpkg -l | grep -q libncurses5
    then
        set_mysql_install_info_log "libncurses5 install successfully"
    else
        set_mysql_install_error_log "libncurses5 installation failure"
    fi

    if dpkg -l | grep -q libaio1
    then
        set_mysql_install_info_log "libaio1 install successfully"
    else
        set_mysql_install_error_log "libaio1 installation failure"
    fi
}


function configurate_mysql_filemod_and_user {

    sudo groupadd mysql
    sudo useradd -r -g mysql -s /bin/false mysql

    if is_exist_of_mysql_group 'mysql'
    then
        set_mysql_install_info_log "Group mysql create successfully"
    else
        set_mysql_install_error_log "Failed to create the mysql group"
    fi

    if is_exist_of_mysql_user 'mysql'
    then
        set_mysql_install_info_log "User mysql create successfully"
    else
        set_mysql_install_error_log "Failed to create the mysql user"
    fi

    if ! cd "$MYSQL_INSTALL_PATH"; then
        set_mysql_install_error_log "Cannot enter $MYSQL_INSTALL_PATH"
    fi

    sudo mkdir -p "$MYSQL_DATA_DIR_PATH"

    if ! is_exist_of_mysql_resource "$MYSQL_DATA_DIR_PATH"
    then
        exit 1
    fi

    sudo chown mysql:mysql "$MYSQL_DATA_DIR_PATH"

    sudo chmod 750 "$MYSQL_DATA_DIR_PATH"
}


function initilaize_and_activate_mysql_server {

    cd "$MYSQL_INSTALL_PATH"

    sudo ./bin/mysqld --initialize --user=mysql \
        --lc-messages-dir=${MYSQL_INSTALL_PATH}/share/ \
        --datadir=${MYSQL_INSTALL_PATH}/data/ &> "$MYSQL_INITIALIZE_LOG_PATH"

    sudo bin/mysql_ssl_rsa_setup --datadir=${MYSQL_DATA_DIR_PATH}

    ./bin/mysqld_safe --user=mysql &

    sleep 5

    sudo cp support-files/mysql.server /etc/init.d/mysql.server

    sudo /etc/init.d/mysql.server start

    echo "export PATH=$PATH:$MYSQL_INSTALL_PATH/bin" >> "$MYSQL_ENV_CONF_PATH"
}


set_mysql_install_info_log "Start intsall mysql57 process"

install_dependancies_of_mysql

install_mysql_binary_pkg

configurate_mysql_filemod_and_user

initilaize_and_activate_mysql_server

echo 'Complete!'
