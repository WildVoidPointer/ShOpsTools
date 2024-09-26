curl http://192.168.179.1:8080/cri-dockerd.deb -o cridocker.deb

sudo apt install -y ./cridocker.deb

sudo sed -i \
's|ExecStart=.*|ExecStart=/usr/bin/cri-dockerd --network-plugin=cni --pod-infra-container-image=registry.k8s.io/pause:3.9|' \
/usr/lib/systemd/system/cri-docker.service

sudo systemctl daemon-reload
sudo systemctl enable --now cri-docker