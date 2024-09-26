sudo kubeadm config images pull \
  --cri-socket unix:///var/run/cri-dockerd.sock


sudo kubeadm init \
  --apiserver-advertise-address=192.168.179.140 \
  --kubernetes-version v1.30.0 \
  --service-cidr=10.96.0.0/12 \
  --pod-network-cidr=10.244.0.0/16 \
  --cri-socket unix:///var/run/cri-dockerd.sock \
  --ignore-preflight-errors=all


mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config 

# 忘记令牌
sudo kubeadm token create --print-join-command

# 以令牌加入集群

wget https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

kubectl apply -f kube-flannel.yml




# 
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

sudo kubeadm join 192.168.179.140:6443 --token o7xhmt.q9fobmknv883ker0 \
	--discovery-token-ca-cert-hash sha256:149f67cf7115e058be774630ea1ec7f898c17c48927045df10748aa895db041d \
  --cri-socket unix:///var/run/cri-dockerd.sock

sudo rm -f /etc/kubernetes/pki/ca.crt


