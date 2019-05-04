#!/bin/bash

set -e

for chart in "$@"
do
  helm delete --purge $chart
done
