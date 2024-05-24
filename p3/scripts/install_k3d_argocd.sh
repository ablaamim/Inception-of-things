#!/bin/bash

set -e

# Update the system
sudo dnf update -y

# Remove conflicting packages if they exist
sudo dnf remove -y podman containers-common || true

# Install Docker
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add the current user to the docker group
sudo usermod -aG docker $USER

# Install k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Verify k3d installation
k3d version

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Verify kubectl installation
kubectl version --client

# Create a k3s cluster using k3d
k3d cluster create mycluster

# Verify the cluster is up and running
kubectl get nodes

# Create namespaces
kubectl create namespace argocd
kubectl create namespace dev

# Install ArgoCD in its namespace
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Install ArgoCD CLI
VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
curl -sSL -o argocd-linux-amd64 "https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64"
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# Wait for ArgoCD server to be ready
echo "Waiting for ArgoCD server to be ready..."
while true; do
    PODS=$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o jsonpath="{.items[*].status.phase}")
    if [ -n "$PODS" ]; then
        STATUS=$(echo "$PODS" | head -n 1)
        if [ "$STATUS" == "Running" ]; then
            break
        fi
    fi
    echo "Current status: $STATUS"
    sleep 10
done

# Port-forward the ArgoCD API server
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
# Wait for a few seconds to ensure the port-forward is established
sleep 5

# Retrieve the initial password
argocd_password=$(kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Login to ArgoCD
argocd login localhost:8080 --username admin --password $argocd_password --insecure

kubectl config set-context --current --namespace=argocd

argocd app create will --repo 'https://github.com/ablaamim/Inception-of-things' --path 'p3/app' --dest-namespace 'dev' --dest-server 'https://kubernetes.default.svc' --grpc-web


# Apply the deployment configuration
#kubectl apply -f deployment.yaml -n dev

# Trigger synchronization in ArgoCD
argocd app sync wil-app-v1 --grpc-web
sleep 5

echo "\033[0;36mView created app after sync and configuration\033[0m"
argocd app get will --grpc-web

echo "Docker, k3d, kubectl, and ArgoCD have been installed successfully."
echo "Deployment configuration has been applied to the dev namespace using ArgoCD."
echo "ArgoCD application synchronization has been triggered."
echo "Please log out and log back in to apply Docker group changes."

