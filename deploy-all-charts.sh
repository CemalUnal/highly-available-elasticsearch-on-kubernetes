#!/bin/bash

set -e

for chart in "$@"
do
  app_name="${chart%%:*}"
  namespace="${chart##*:}"
  bash deploy-helm-chart.sh --release-name=$app_name --namespace=$namespace --helm-chart-path=$app_name --values-yaml="values.yaml"
done
