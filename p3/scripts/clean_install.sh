#!/bin/bash

set -e

# Stop and disable Docker
sudo systemctl stop docker
sudo systemctl disable docker

# Remove Docker packages
sudo dnf remove -y docker-ce docker-ce-cli containerd.io

# Remove Docker repo
sudo rm -f /etc/yum.repos.d/docker-ce.repo

# Remove Docker group
sudo groupdel docker || true

# Remove Docker directories
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

# Uninstall k3d
sudo rm -f /usr/local/bin/k3d

# Uninstall kubectl
sudo rm -f /usr/local/bin/kubectl

# Delete k3s cluster
k3d cluster delete mycluster || true

# Remove ArgoCD namespace
kubectl delete namespace argocd || true

# Uninstall ArgoCD CLI
sudo rm -f /usr/local/bin/argocd

# Clean up any remaining k3d and k3s configurations
sudo rm -rf ~/.kube
sudo rm -rf ~/.config/k3d
sudo rm -rf /etc/rancher/k3s

# Optionally, remove any remaining podman and containers-common packages
sudo dnf remove -y podman containers-common || true

# Clean up any leftover package caches
sudo dnf clean all

echo "Docker, k3d, kubectl, and ArgoCD have been successfully removed."

