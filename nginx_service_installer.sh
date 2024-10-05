#!/bin/bash

NGINX_VERSION='1.26.2'
NGINX_SRC_URL="https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"
# NGINX=`echo $NGINX_PKG | cut -d '.' -f 1-3`
NGINX_PACKAGE_NAME="nginx-${NGINX_VERSION}.tar.gz"
NGINX_SRCD="nginx-${NGINX_VERSION}"
NGINX_INSTALL_D='/usr/local/nginx'


# if [ "$USER" != 'root' ];
# then
#     echo "Not"
#     exit 1
# fi

if ! (sudo apt-get install -y gcc-* pcre-devel zlib-devel 1> /dev/null)
then
    echo "ERROR"
fi

if curl -LO "$NGINX_SRC_URL" &> /dev/null
then
    tar -xf "$NGINX_PACKAGE_NAME"
    if [ ! -d "$NGINX_SRCD" ]
    then
        echo "ERROR"
        exit 1
    fi
else
    echo "ERROR"
    exit 1
fi

cd "$NGINX_SRCD"
if ./configure --prefix="$NGINX_INSTALL_D"
then
    if make
    then
        if make install 
        then
            echo 'Install OK'
        fi
    else
        echo 'Install NOT'
    fi
else
    echo "Configure NOT"
fi


