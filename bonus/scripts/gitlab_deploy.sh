#!/bin/bash

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

kubectl create namespace gitlab

helm repo add gitlab https://charts.gitlab.io/

helm repo update

helm upgrade --install gitlab gitlab/gitlab --namespace gitlab --values ../confs/values.yaml


#loop to wait


kubectl port-forward svc/gitlab-webservice-default -n gitlab 9090:8181 &


