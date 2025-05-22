#!/bin/bash


if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root!"
    exit 1
fi

cp ./smb.conf /etc/samba/

pkill smbd && smbd -D
