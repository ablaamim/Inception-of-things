#!/bin/bash


# Install ArgoCD CLI (command-line interface)
VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
curl -sSL -o argocd-linux-amd64 "https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64"
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

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

echo "created"
