#!/bin/bash

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

kubectl create namespace gitlab

helm repo add gitlab https://charts.gitlab.io/

helm repo update

helm upgrade --install gitlab gitlab/gitlab --namespace gitlab --values ../confs/values.yaml

NAMESPACE="gitlab"
INTERVAL=5  # Interval in seconds between checks

echo "Waiting for all pods in namespace $NAMESPACE to be either running or completed..."

while true; do
    # Get all pods that are not in Running or Succeeded state
    NOT_READY_PODS=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running,status.phase!=Succeeded -o jsonpath='{.items[*].metadata.name}')

    if [ -z "$NOT_READY_PODS" ]; then
        echo "All pods in namespace $NAMESPACE are either running or completed."
        break
    else
        echo "The following pods are not in running or completed state: $NOT_READY_PODS"
        echo "Checking again in $INTERVAL seconds..."
        sleep $INTERVAL
    fi
done

echo "All pods in namespace $NAMESPACE are now either running or completed."

kubectl port-forward svc/gitlab-webservice-default -n gitlab 80:8181 &

sleep 2

