#!/bin/bash

# USAGE 
# $ bash deploy-all-charts.sh

set -e

charts=(
  "elasticsearch:ha-elasticsearch-cluster"
  "fluentd:kube-logging"
  "grafana:kube-monitoring"
  "kibana:kube-logging"
  "kube-state-metrics:kube-monitoring"
  "node-exporter:kube-monitoring"
  "prometheus:kube-monitoring"
)

for attribute in "${charts[@]}"
do
  app_name="${attribute%%:*}"
  namespace="${attribute##*:}"
  bash deploy-helm-chart.sh --release-name=$app_name --namespace=$namespace --helm-chart-path=$app_name --values-yaml="values.yaml"
done
