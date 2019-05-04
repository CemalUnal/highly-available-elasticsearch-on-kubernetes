#!/bin/bash

set -e

for i in "$@"
do
case $i in
    --release-name=*)
    release_name="${i#*=}"
    ;;
    --namespace=*)
    namespace="${i#*=}"
    ;;
    --helm-chart-path=*)
    helm_chart_path="${i#*=}"
    ;;
    --values-yaml=*)
    values_yaml="${i#*=}"
    ;;
    *)
    ;;
esac
done

cd ./$helm_chart_path

release_name_truncated=$(echo $release_name | cut -c -52)

function check_failed_release_exists {
  helm ls --short --failed | grep $1
}

function check_release_exists {
  helm ls --all --short | grep $1
}

function deploy_helm_chart {
  if check_release_exists $1; then
    echo "Upgrading existing release..."
    helm upgrade -f $values_yaml $1 . --namespace $2
  else
    echo "Installing new release..."
    helm install --values $values_yaml --name $1 . --namespace $2
  fi
}

if check_failed_release_exists $release_name_truncated; then
  helm del $(helm ls --short --failed | grep $release_name_truncated) --purge
else
  echo "there are no failed releases to remove"
fi

deploy_helm_chart $release_name_truncated $namespace && cd ../