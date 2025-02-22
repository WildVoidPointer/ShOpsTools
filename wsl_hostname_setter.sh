#!/bin/bash


WSL_CONFIG_PATH='/etc/wsl.conf'
HOSTNAME_PATH='/etc/hostname'


function set_wsl_host_conf {
    echo -e "Write $WSL_CONFIG_PATH configuration as follows:\n"
    echo '[user]' | sudo tee -a "$WSL_CONFIG_PATH"
    echo 'default=r123' | sudo tee -a "$WSL_CONFIG_PATH"
    echo '[network]' | sudo tee -a "$WSL_CONFIG_PATH"
    echo 'generateResolvConf=true' | sudo tee -a "$WSL_CONFIG_PATH"
    echo 'hostname=localhost' | sudo tee -a "$WSL_CONFIG_PATH"
    echo 'localhost' | sudo tee "$HOSTNAME_PATH" > /dev/null
}


set_wsl_host_conf
