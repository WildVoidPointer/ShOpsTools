#!/bin/bash

ini_file="config.ini"
section="database"
key="host"

# 解析 ini 文件
value=$(sed -n "/^\[$section\]/,/^\[/{s/^[[:space:]]*$key[[:space:]]*=[[:space:]]*//p}" "$ini_file")

echo "[$section] $key = $value"
