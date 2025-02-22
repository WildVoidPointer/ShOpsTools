#!/bin/bash


ADMIN_HOST_IPADDR=$(cat /etc/resolv.conf | grep -oP '(?<=nameserver\ ).*')
SHELL_PROFILE_PATH="~./.bashrc"
PROXY_PORT=7897


cat >> "$SHELL_PROFILE_PATH" <<EOF

set_proxy() {
    export https_proxy="http://${ADMIN_HOST_IPADDR}:${PROXY_PORT}"
    export http_proxy="http://${ADMIN_HOST_IPADDR}:${PROXY_PORT}"
    export all_proxy="http://${ADMIN_HOST_IPADDR}:${PROXY_PORT}"

    echo -e "Acquire::http::Proxy \"http://${ADMIN_HOST_IPADDR}:${PROXY_PORT}\";" \
    | sudo tee -a /etc/apt/apt.conf.d/proxy.conf > /dev/null

    echo -e "Acquire::https::Proxy \"http://${ADMIN_HOST_IPADDR}:${PROXY_PORT}\";" \
    | sudo tee -a /etc/apt/apt.conf.d/proxy.conf > /dev/null
}


unset_proxy() {
    unset https_proxy
    unset http_proxy
    unset all_proxy
    sudo sed -i -e "/Acquire::http::Proxy/d" /etc/apt/apt.conf.d/proxy.conf
    sudo sed -i -e "/Acquire::https::Proxy/d" /etc/apt/apt.conf.d/proxy.conf
}


export -f set_proxy
export -f unset_proxy

EOF

source "$SHELL_PROFILE_PATH"
