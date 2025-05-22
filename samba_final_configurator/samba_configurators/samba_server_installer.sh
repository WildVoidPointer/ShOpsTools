#!/bin/bash


if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root!"
    exit 1
fi

apt-get update

apt-get install -y samba

apt-get install -y smbclient

