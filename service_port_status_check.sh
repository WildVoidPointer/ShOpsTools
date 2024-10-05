#!/bin/bash

host='example.com'  # 请将此处替换为具体的主机名或IP
port=22

t_port_status=$(mktemp port_status.XXX)

# 检查 telnet 是否存在
if ! command -v telnet &> /dev/null; then
    echo "telnet: command not found"
    exit 1
fi

# 执行 telnet 检查端口是否开放
(telnet "$host" "$port" <<EOF
quit
EOF) &> "$t_port_status";

# 根据 telnet 输出信息检查端口状态
if grep "Connected" "$t_port_status" &> /dev/null
then
    echo "$host $port is open"
else
    echo "$host $port is closed"
fi

# 清理临时文件
rm -f "$t_port_status"
