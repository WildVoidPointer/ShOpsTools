#!/bin/bash


WSL_CONF_PATH='/etc/wsl.conf'
HOSTNAME_PATH='/etc/hostname'


if [ "$UID" -ne 0 ]; then
    echo "Please run the script with root permission to perform the configuration"
    exit 1
fi


sudo cat > "$WSL_CONF_PATH" <<EOF
[user]
default=r123
[network]
generateResolvConf=true
hostname=localhost
EOF


echo 'localhost' | sudo tee "$HOSTNAME_PATH" > /dev/null

set_wsl_host_conf
