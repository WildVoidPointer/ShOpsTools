#!/bin/bash

set -u

WSL_CONF_PATH="/etc/wsl.conf"

DEFAULT_HOSTNAME="localhost"


# ERROR_CODE
RUN_EUSER_ERROR=1
WSL_CONF_BACKUP_ERROR=2


function euser_is_root {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run this script as the root user"
        exit "$RUN_EUSER_ERROR"
    fi
}


function network_is_define {
    grep -q '\[network\]' "$WSL_CONF_PATH"
    return "$?"
}


function hostname_of_net_is_define {
    grep -q '^hostname' "$WSL_CONF_PATH"
    return "$?"
}


function old_wsl_conf_backup {
    cp -a "$WSL_CONF_PATH" "${WSL_CONF_PATH}.bak"

    if [ "$?" -ne 0 ]; then
        echo 'Backup of the wsl.conf file failed'
        exit "$WSL_CONF_BACKUP_ERROR"
    fi
}


function generate_hostname_wsl_conf {
    cat > "$WSL_CONF_PATH" <<EOF
[network]
hostname = "$DEFAULT_HOSTNAME"
EOF
}


function main {
    euser_is_root

    if [ ! -f "$WSL_CONF_PATH" ]; then
        echo 'A simple wsl.conf file will be automatically generated'
        generate_hostname_wsl_conf
        return "$?"
    else
        old_wsl_conf_backup
    fi

    if network_is_define; then
        if hostname_of_net_is_define; then
            sed -i "/^hostname/{
                s/^/# /
                a\
                hostname = \"$DEFAULT_HOSTNAME\"
                }" "$WSL_CONF_PATH"

        else
            sed -i \
                "/\[network\]/ \
                a\
                hostname = \"$DEFAULT_HOSTNAME\"" \
                "$WSL_CONF_PATH" 
        fi
    fi
}


main
