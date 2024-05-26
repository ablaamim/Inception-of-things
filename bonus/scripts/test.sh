#!/bin/bash

# Retrieve the initial ArgoCD admin password from the Kubernetes secret
kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

sleep 2

# Login to ArgoCD using the initial admin credentials
argocd login localhost:8080 --username admin --password eJDY58jRTlgF8cqa --insecure

sleep 2


# Create a new ArgoCD application
argocd app create will --repo 'http://gitlab.ablaamim.gitlab.io/root/inception-of-things.git' --path 'app' --dest-namespace 'dev' --dest-server 'https://kubernetes.default.svc' --grpc-web

sleep 2

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

