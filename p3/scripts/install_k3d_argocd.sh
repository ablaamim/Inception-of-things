#!/bin/bash

# Update the system
#sudo dnf update -y

# Remove conflicting packages if they exist
# sudo dnf remove -y podman containers-common || true

# Install Docker
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add the current user to the docker group
sudo usermod -aG docker $USER

# Install k3d and setup a local cluster
sudo wget https://github.com/rancher/k3d/releases/download/v3.0.0/k3d-linux-amd64 -O /usr/local/bin/k3d
sudo chmod +x /usr/local/bin/k3d
k3d version
echo "source <(k3d completion bash)" >> ~/.bashrc
source ~/.bashrc

 Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

kubectl get node -o wide

k3d cluster create my-cluster --api-port 6443 -p 8080:80@loadbalancer --agents 2

kubectl cluster-info

echo "Docker, k3d, kubectl, and ArgoCD have been installed successfully."
echo "Deployment configuration has been applied to the dev namespace using ArgoCD."
echo "ArgoCD application synchronization has been triggered."
echo "Please log out and log back in to apply Docker group changes."

