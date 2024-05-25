#!/bin/bash

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
k3d --version

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

#kubectl get nodes -o wide

k3d cluster create dev-cluster

rm install.yaml

kubectl create namespace argocd
kubectl create namespace dev

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Install ArgoCD CLI
#VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
#curl -sSL -o argocd-linux-amd64 "https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64"
#sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
#rm argocd-linux-amd64

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

rm project.yaml application.yaml

cat > project.yaml << EOF
kind: AppProject
metadata:
  name: argocdrocks-project
  labels:
    app: argocdrocks
spec:
  # Project description
  description: Our ArgoCD Project to deploy our app locally
  # Allow manifests to deploy only from Sokube git repositories
  sourceRepos:
  - "https://github.com/ablaamim/Inception-of-things.git"
  # Only permit to deploy applications in the same cluster
  destinations:
  - namespace: dev
    server: https://kubernetes.default.svc
  # Enables namespace orphaned resource monitoring.
  orphanedResources:
    warn: false
EOF

kubectl create -n argocd -f project.yaml

cat > application.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Application
metadata:
  labels:
    app: argocdrocks
  name: argocdrocks-app
spec:
  project: argocdrocks-project
  source:
    repoURL: https://github.com/sokube/argocd-rocks.git
    targetRevision: featurebranch_1
    path: app
    directory:
      recurse: true
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: false
      selfHeal: true
EOF

kubectl apply -f application.yaml -n argocd

#kubectl apply -f ingress.yaml -n argocd

# Port-forward the ArgoCD API server
#kubectl port-forward svc/argocd-server -n argocd 9090:443 &
# Wait for a few seconds to ensure the port-forward is established
#sleep 5

# Retrieve the initial password
#argocd_password=$(kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Login to ArgoCD
#argocd login localhost:9090 --username admin --password $argocd_password --insecure

#kubectl config set-context --current --namespace=argocd

#argocd app create will --repo 'https://github.com/ablaamim/Inception-of-things.git' --path 'p3/app' --dest-namespace 'dev' --dest-server 'https://kubernetes.default.svc' --grpc-web

#k3d cluster create my-cluster --api-port 6443 -p 8080:80@loadbalancer --agents 2

#sleep 5;

#kubectl cluster-info


# Apply the deployment configuration
#kubectl apply -f deployment.yaml -n dev

# Trigger synchronization in ArgoCD
#argocd app sync wil-app-v1 --grpc-web
#sleep 5

#echo "\033[0;36mView created app after sync and configuration\033[0m"
#argocd app get will --grpc-web

echo "Docker, k3d, kubectl, and ArgoCD have been installed successfully."
echo "Deployment configuration has been applied to the dev namespace using ArgoCD."
echo "ArgoCD application synchronization has been triggered."
echo "Please log out and log back in to apply Docker group changes."

