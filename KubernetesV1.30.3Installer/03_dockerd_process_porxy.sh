sudo mkdir -p /etc/systemd/system/docker.service.d

sudo bash -c 'cat <<EOF > /etc/systemd/system/docker.service.d/http-proxy.conf
[Service]
Environment="HTTP_PROXY=http://192.168.179.130:7897"
Environment="HTTPS_PROXY=http://192.168.179.130:7897"
Environment="NO_PROXY=localhost,127.0.0.1,.example.com"
EOF'

sudo systemctl daemon-reload
sudo systemctl restart docker
