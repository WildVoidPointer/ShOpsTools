#!/bin/bash


WSL_CONFIG_PATH='/etc/wsl.conf'
HOSTNAME_PATH='/etc/hostname'
echo '[user]' | sudo tee -a "$WSL_CONFIG_PATH"
echo 'default=r123' | sudo tee -a "$WSL_CONFIG_PATH"
echo '[network]' | sudo tee -a "$WSL_CONFIG_PATH"
echo 'generateResolvConf=true' | sudo tee -a "$WSL_CONFIG_PATH"
echo 'hostname=localhost' | sudo tee -a "$WSL_CONFIG_PATH"
sudo echo 'localhost' > "$HOSTNAME_PATH"
