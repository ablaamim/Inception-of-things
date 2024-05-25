#!/bin/bash

cat credentials.yml | grep 'ARGOCD_PASSWORD:'
cat credentials.yml | grep 'ARGOCD_ADDRESS:'

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

kubectl create namespace gitlab

kubectl config set-context --current --namespace=gitlab
helm repo add gitlab https://charts.gitlab.io

helm install --namespace 'gitlab' gitlab-runner \
                        --set gitlabUrl='https://gitlab.com/',runnerRegistrationToken='GR1348941FqxLR1_Ec8krbsHE6LqM',rbac.create='true' \
                        gitlab/gitlab-runner

kubectl wait pods -n gitlab --all --for condition=Ready --timeout=600s

kubectl describe pods gitlab-runner --namespace=gitlab

