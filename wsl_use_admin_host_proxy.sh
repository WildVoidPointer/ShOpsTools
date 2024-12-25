#!/bin/bash


host_ipaddr=$(cat /etc/resolv.conf | grep -oP '(?<=nameserver\ ).*')
proxy_port=7897


set_proxy() {
    export https_proxy="http://${host_ipaddr}:${proxy_port}"
    export http_proxy="http://${host_ipaddr}:${proxy_port}"
    export all_proxy="http://${host_ipaddr}:${proxy_port}"
    echo -e "Acquire::http::Proxy \"http://${host_ipaddr}:${proxy_port}\";" | sudo tee -a /etc/apt/apt.conf.d/proxy.conf > /dev/null
    echo -e "Acquire::https::Proxy \"http://${host_ipaddr}:${proxy_port}\";" | sudo tee -a /etc/apt/apt.conf.d/proxy.conf > /dev/null
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

