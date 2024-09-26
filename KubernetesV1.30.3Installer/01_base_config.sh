sudo systemctl stop firewalld
sudo systemctl disable firewalld

sudo swapoff -a
sudo sed -ri 's/.*swap.*/#&/' /etc/fstab

sudo hostnamectl set-hostname k8s-m

sudo tee -a /etc/hosts <<EOF
192.168.179.140 k8s-m
192.168.179.141 k8s-n1
192.168.179.142 k8s-n2
EOF

sudo apt install -y ntpdate
sudo ntpdate time.windows.com

