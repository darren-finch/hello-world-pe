#!/bin/bash
set -e

# Install Docker
apt-get update
apt-get install -y docker.io
systemctl enable --now docker
usermod -aG docker ubuntu

# Install k3s
curl -sfL https://get.k3s.io | sh -

# Allow ubuntu user to use kubectl
mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube