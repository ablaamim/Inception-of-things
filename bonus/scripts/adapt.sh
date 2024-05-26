# Port-forward the ArgoCD API server to make it accessible locally on port 8080
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
# Wait for a few seconds to ensure the port-forward is established
sleep 5

# Retrieve the initial ArgoCD admin password from the Kubernetes secret
argocd_password=$(kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Login to ArgoCD using the initial admin credentials
argocd login localhost:8080 --username admin --password $argocd_password --insecure

# Create a new ArgoCD application
argocd app create will --repo 'https://github.com/ablaamim/Inception-of-things.git' --path 'p3/app' --dest-namespace 'dev' --dest-server 'https://kubernetes.default.svc' --grpc-web

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


