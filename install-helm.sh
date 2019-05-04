#!/bin/bash

set -e

echo "Fetching the Helm installation script..."
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh

echo "Making the script executable..."
chmod a+x get_helm.sh

echo "Executing the Helm installation script..."
bash get_helm.sh

echo "Initializing Helm..."
helm init

echo "Create service account and role binding..."
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller

echo "Pathcing tiller deployment..."
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
