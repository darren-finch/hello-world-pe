#!/bin/bash
set -e

# Install Docker
apt-get update
apt-get install -y docker.io
systemctl enable --now docker
usermod -aG docker ubuntu

# Install k3s — include the public IP as a TLS SAN so external kubectl works
PUBLIC_IP=$(curl -s http://169.254.169.254/opc/v1/vnics/ | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['publicIp'])" 2>/dev/null || echo "")
K3S_EXEC="--write-kubeconfig-mode=644"
if [ -n "$PUBLIC_IP" ]; then
  K3S_EXEC="$K3S_EXEC --tls-san $PUBLIC_IP"
fi
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="$K3S_EXEC" sh -

# Wait for k3s to finish starting and write its kubeconfig
until [ -f /etc/rancher/k3s/k3s.yaml ]; do sleep 2; done

# Allow ubuntu user to use kubectl without sudo
mkdir -p /home/ubuntu/.kube
if [ -n "$PUBLIC_IP" ]; then
  sed "s/127.0.0.1/$PUBLIC_IP/g" /etc/rancher/k3s/k3s.yaml > /home/ubuntu/.kube/config
else
  cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
fi
chown -R ubuntu:ubuntu /home/ubuntu/.kube
chmod 600 /home/ubuntu/.kube/config

# Set KUBECONFIG for ubuntu user in their shell profile
echo 'export KUBECONFIG=$HOME/.kube/config' >> /home/ubuntu/.bashrc

# Open required ports in iptables (OCI Ubuntu blocks inbound by default)
iptables -I INPUT -p tcp --dport 22 -j ACCEPT
iptables -I INPUT -p tcp --dport 80 -j ACCEPT
iptables -I INPUT -p tcp --dport 443 -j ACCEPT
iptables -I INPUT -p tcp --dport 6443 -j ACCEPT

# Persist iptables rules across reboots
apt-get install -y iptables-persistent
netfilter-persistent save