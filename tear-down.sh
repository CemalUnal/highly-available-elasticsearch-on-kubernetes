#!/bin/bash

set -e

kubectl delete -f kubernetes-manifests/elasticsearch/statefulset.yaml
kubectl delete pvc elasticsearch-volume-ha-elasticsearch-0
kubectl delete pvc elasticsearch-volume-ha-elasticsearch-1
kubectl delete pvc elasticsearch-volume-ha-elasticsearch-2
kubectl delete -f kubernetes-manifests/elasticsearch/persistent-volume.yaml
kubectl delete -f kubernetes-manifests/elasticsearch/service.yaml
