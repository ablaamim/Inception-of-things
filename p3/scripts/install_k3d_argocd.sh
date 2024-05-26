#!/bin/bash

# Exit immediately if a command exits with a non-zero status
#set -e

# Install Docker
# Add the Docker repository to the dnf package manager
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
# Install Docker packages
sudo dnf install -y docker-ce docker-ce-cli containerd.io

# Start and enable Docker service to start on boot
sudo systemctl start docker
sudo systemctl enable docker

# Add the current user to the docker group to allow running docker without sudo
sudo usermod -aG docker $USER

# Install k3d, a tool for running k3s (Lightweight Kubernetes) in Docker
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Verify k3d installation by displaying its version
k3d --version

# Install kubectl, the command-line tool for interacting with Kubernetes clusters
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# Move the kubectl binary to a directory in your PATH
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
# Remove the downloaded kubectl binary to clean up
rm kubectl

# Create a new k3d cluster named "dev-cluster"
k3d cluster create dev-cluster


# Create Kubernetes namespaces for ArgoCD and the application
kubectl create namespace argocd
kubectl create namespace dev

# Install ArgoCD in the argocd namespace using the provided installation manifest
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Install ArgoCD CLI (command-line interface)
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# Wait for ArgoCD server to be ready by checking the status of the pods in the argocd namespace
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

# Port-forward the ArgoCD API server to make it accessible locally on port 8080
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
# Wait for a few seconds to ensure the port-forward is established
sleep 5

# Retrieve the initial ArgoCD admin password from the Kubernetes secret
argocd_password=$(kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo $argocd_password

# Login to ArgoCD using the initial admin credentials
argocd login localhost:8080 --username admin --password $argocd_password --insecure

sleep 5

# Create a new ArgoCD application
argocd app create will --repo 'https://github.com/ablaamim/Inception-of-things.git' --path 'p3/app' --dest-namespace 'dev' --dest-server 'https://kubernetes.default.svc' --grpc-web

sleep 5

# Retrieve details of the newly created application
argocd app get will --grpc-web
# Sleep for 5 seconds to prevent potential connection issues
sleep 5

# Synchronize the application state with the git repository
argocd app sync will --grpc-web
# Sleep for 5 seconds to prevent potential connection issues
sleep 5

# Set the application to automatically synchronize changes
argocd app set will --sync-policy automated --grpc-web
# Sleep for 5 seconds to prevent potential connection issues
sleep 5

# Set the application to automatically prune resources that are removed from the git repository
argocd app set will --auto-prune --allow-empty --grpc-web
# Sleep for 5 seconds to prevent potential connection issues
sleep 5

# Retrieve details of the application again to confirm the settings
argocd app get will --grpc-web

# Print final messages indicating successful installation and setup
echo "Docker, k3d, kubectl, and ArgoCD have been installed successfully."
echo "Deployment configuration has been applied to the dev namespace using ArgoCD."
echo "ArgoCD application synchronization has been triggered."
echo "Please log out and log back in to apply Docker group changes."

