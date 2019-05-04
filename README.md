# Highly Available Elasticsearch on top of Kubernetes

## Introduction

### Abstract
This project contains the manifests that are used to deploy highly available Elasticsearch cluster and also the monitoring tools that are used to follow some metrics and debugging.

Currently I am using Managed Kubernetes service on DigitalOcean. My Kubernetes cluster consist of 3 worker nodes. And the master nodes are managed by DigitalOcean. Kubernetes version v1.14.1 and Docker 18.9.2 is installed all of the worker nodes.

Worker node specs;
- 8 GB Memory
- 4 vCPUs
- 160 GB SSD Disk

Below you can find the links to access the resources that are deployed in the assignment;

- Elasticsearch cluster is available at http://188.166.133.222:9200/
- Grafana dashboards are available at
    - http://188.166.134.220:3000/d/8fpzp0mgtvsr52bk99cdbg5xxt6jnzd6/kubernetes-cluster-monitoring-picnic
    - http://188.166.134.220:3000/d/98wzmmtojsqf3gjh11rr7hynxqrgqjv4/kubernetes-namespace-monitoring-picnic
- Kibana dashboard is available at http://188.166.135.10:5601/app/kibana#/dashboard/04dae180-336f-11e8-9f03-db5dae1ff024

### Tools Used
[Helm](https://helm.sh) is used to deploy Kubernetes resources. Helm provides important facilities. These are;

- Installing a detailed application to the Kubernetes with one command
- Upgrading an application that is already deployed to the Kubernetes
- Rolling back an application deployment and return to a previous release when something goes wrong

[Prometheus](https://prometheus.io/), [Node Exporter](https://github.com/prometheus/node_exporter#node-exporter), [Kube State Metrics](https://github.com/kubernetes/kube-state-metrics#overview), [Grafana](https://grafana.com/) stack is used to monitor resource utilisation of Kubernetes nodes and pods that are running in Kubernetes.

[Fluentd](https://www.fluentd.org/) and [Kibana](https://www.elastic.co/products/kibana) are used to aggregate and visualize the pod logs across the Kubernetes cluster. They are connecting to the highly available Elasticsearch cluster.

## Installation

### Prerequisites

- [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/) cli v1.14.1
- Access to a Kubernetes cluster.
    - Valid config file under the $HOME/.kube/ directory named as config.
- Docker as container runtime in your Kubernetes nodes.

Validate your kubectl installation with the following command;
```console
kubectl get nodes -owide

NAME                  STATUS  VERSION  OS-IMAGE                       CONTAINER-RUNTIME
pool-goa4adyjv-qv05   Ready   v1.14.1  Debian GNU/Linux 9 (stretch)   docker://18.9.2
.....
.....
```

Change your directory to root folder of this project. And then execute the following command to install Helm command line tool to your local environment and deploy Tiller to the Kubernetes;

```console
bash install-helm.sh
```

Wait until the Tiller deployment is ready;

```console
kubectl get deploy -n kube-system | grep -i tiller

NAME              READY   UP-TO-DATE   AVAILABLE   AGE
tiller-deploy     1/1     1            1           10h
```

Execute the following command to deploy highly available Elasticsearch cluster and monitoring tools to the Kubernetes:

```console
# Set a map in the terminal that contains the chart directories as keys and namespaces as values
charts=(
  "elasticsearch:ha-elasticsearch-cluster"
  "fluentd:kube-logging"
  "kibana:kube-logging"
  "prometheus:kube-monitoring"
  "node-exporter:kube-monitoring"
  "kube-state-metrics:kube-monitoring"
  "grafana:kube-monitoring"
)

# Then execute the script to deploy the charts
bash deploy-all-charts.sh "${charts[@]}"
```

It will deploy the Helm charts for the following applications/tools;

- Elasticsearch
- Prometheus
- Kube State Metrics
- Node Exporter
- Grafana
- Fluentd
- Kibana

and creates the following namespaces;

- ha-elasticsearch-cluster
- kube-logging
- kube-monitoring

Verify the installation by executing the following commands:

```console
helm ls
NAME              	REVISION            STATUS
elasticsearch     	1         	    DEPLOYED            ....
fluentd           	1       	    DEPLOYED            ....
grafana           	1       	    DEPLOYED            ....
kibana            	1       	    DEPLOYED            ....
kube-state-metrics	1       	    DEPLOYED            ....
node-exporter     	1       	    DEPLOYED            ....
prometheus        	1       	    DEPLOYED            ....


kubectl get pods -n ha-elasticsearch-cluster

NAME                 READY   STATUS
ha-elasticsearch-0   1/1     Running
ha-elasticsearch-1   1/1     Running
ha-elasticsearch-2   1/1     Running

kubectl get pods -n kube-logging

NAME                      READY   STATUS
fluentd-hlf6k             1/1     Running
fluentd-kpcvd             1/1     Running
fluentd-l5rnw             1/1     Running
kibana-7bc7984bf5-pmfql   1/1     Running

kubectl get pods -n kube-monitoring

NAME                                  READY   STATUS
grafana-8675988864-rbhgf              1/1     Running
kube-state-metrics-7986d88c55-jjfzn   2/2     Running
node-exporter-ct4ft                   1/1     Running
node-exporter-gpmgt                   1/1     Running
node-exporter-wlhhw                   1/1     Running
prometheus-7b476bf58c-nvnwq           1/1     Running
```

## Access the Elasticsearch Cluster
The Elasticsearch cluster is exposed by a load balancer in DigitalOcean. You can test the cluster is up and running by executing the following command;

```console
curl -XGET http://188.166.133.222:9200/_cluster/stats?pretty
```
Alternatively, if you want to use forward the Elasticsearch service port to your local environment, execute the following command;

```console
kubectl port-forward ha-elasticsearch-0 9200:9200 -n ha-elasticsearch-cluster
```
Then test it with the following command;

```console
curl -XGET http://localhost:9200/_cluster/stats?pretty
```

## Elasticsearch Cluster Deployment Details
There is a values.yaml file in each Helm chart directory. You can edit this file in case you want to deploy a chart with a different config.

Since Elasticsearch is a stateful service, its chart will be deployed as StatefulSet. Each pod of the StatefulSet will be scheduled on different worker nodes. Since I have 3 worker nodes, I have set the replica count to 3 in the [values.yaml](./elasticsearch/values.yaml). This count can be increased as we join more worker nodes to the Kubernetes cluster. Here are the environment variables used below;

- **ES_JAVA_OPTS** will be set to "-Xms4g -Xmx4g" since I have 8 GB of memory in each Kubernetes worker nodes.

- **discovery.seed_hosts** will be set to node names of the Elasticsearch cluster to provide a list of other nodes in the cluster that are master-eligible and contactable. Kubernetes service dns names are used to provide hostnames. Its value is automatically generated from the [values.yaml](elasticsearch/values.yaml) and [helpers.tpl](/elasticsearch/templates/_helpers.tpl) files. In my case the value is `ha-elasticsearch-0.ha-elasticsearch,ha-elasticsearch-1.ha-elasticsearch,ha-elasticsearch-2.ha-elasticsearch`. Here it will use the default 9300 port to connect to Elasticsearch cluster nodes since I am providing only the hostnames.

- **cluster.initial_master_nodes** will be set to the node names of the Elasticsearch cluster. All of the Elasticsearch nodes will start as master-eligible. In my case the value is `ha-elasticsearch-0.ha-elasticsearch,ha-elasticsearch-1.ha-elasticsearch,ha-elasticsearch-2.ha-elasticsearch`

### Split-Brain Issue

While increasing the replica count of the StatefulSet, we need to consider the "split-brain" issue. Number of master-eligible nodes should be an odd number. Also **discovery.zen.minimum_master_nodes** environment variable should set to  N/2 + 1, and rounding the result down to the closest integer (where N is the number of master eligible nodes). With my current configuration **discovery.zen.minimum_master_nodes** is set to 2. Each Elasticsearch cluster instance is master-eligible since they will start running with the same role. (It is indicated in the assignment sheet.) 


### High Availability - Tolerating Node Failure

Normally, more than one Statefulset pods may locate in the same Kubernetes host. If more than one instance of the Elasticsearch cluster will schedule to the same Kubernetes host, and this host will become unavailable, the end users may experince an outage until the pod rescheduled to another host or host become available. To prevent such an outage, we can schedule each pod to a different Kubernetes host. In order to do this, I have added the following part to the Elasticsearch Statefulset manifest;

```
affinity:
    podAntiAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                    - key: "app"
                        operator: In
                        values:
                        - ha-elasticsearch
            topologyKey: "kubernetes.io/hostname"
```

We can check the node names for each pod are different;
```console
for i in 0 1 2; 
do 
    kubectl get pod ha-elasticsearch-$i -n ha-elasticsearch-cluster --template {{.spec.nodeName}}; echo "";
done

# result
pool-goa4adyjv-qv0k
pool-goa4adyjv-qv05
pool-goa4adyjv-qv0h
```

Also I have created PodDisruptionBudget to indicate that at most one pod from the Elasticsearch StatefulSet can be unavailable at any time. You can change this value in the [values.yaml](./elasticsearch/values.yaml)

### Updating the Deployment
When we want to deploy a new version of our Elasticsearch chart or when we want to change the configs of it, we can use `helm upgrade` command. Also with the help of Kubernetes liveness and readiness probes, we can update our Elasticsearch cluster with no downtime.

```console
helm upgrade -f values.yaml . --namespace ha-elasticsearch-cluster
helm ls | grep elasticsearch
NAME              	REVISION            STATUS
elasticsearch     	2         	    DEPLOYED
```
We can see the revision count is incremented by one.

### Rolling Back the Deployment
When something goes wrong with a deployment update, we may want to perform a rollback operation to return the last stable version of our deployment. With the help of Helm, rollback operation can be achieved easily by using `helm rollback`. When we perform an install, upgrade or rollback operation, Helm increments the revision number. Later on, we can use this revision number to rollback our deployment.

```console
helm rollback elasticsearch 1

# And see the rollback effect
kubectl get pods -n ha-elasticsearch-cluster -w
```

### Backing up Persistent Volumes
DigitalOcean volume backups can be used to backup the data that is provisioned by Kubernetes StorageClass and used by Elasticsearch cluster. Although this is not the best solution since its not cloud agnostic. Also there are other tools that help backing up volumes even the Kubernetes cluster itself. But I am not very familiar with these tools.

### Monitoring & Debugging

#### Monitoring

Since Elastichsearch is a stateful application, we need to monitor its disk usage. By monitoring the disk usage, we can take action to increase the disk size.

Also by monitoring the CPU and Memory consumption by the Kubernetes worker nodes, we can decide to expand the cluster by adding new worker nodes.

Prometheus and Grafana mainly used to monitor the cluster. Grafana chart will be deployed with preconfigured data source and dashboards. Currently you can view two different dashboards in Grafana;
- [Kubernetes Cluster Monitoring](http://188.166.134.220:3000/d/8fpzp0mgtvsr52bk99cdbg5xxt6jnzd6/kubernetes-cluster-monitoring-picnic)
    - Displays live memory/cpu/disk usages of each worker node.

![Kubernetes Cluster Monitoring](/dashboards/grafana/kubernetes-resource-usage-cluster-wide.png)

- [Kubernetes Namespace Monitoring](http://188.166.134.220:3000/d/98wzmmtojsqf3gjh11rr7hynxqrgqjv4/kubernetes-namespace-monitoring-picnic)
    - Displays live memory/cpu/disk usages of each pod in the Kubernetes cluster by namespace.

![Kubernetes Namespace Monitoring](/dashboards/grafana/kubernetes-resource-usage-by-namespace.png)

#### Log Visualization
Fluentd and Kibana mainly used to aggregate and visualize the pod logs across the Kubernetes cluster. They are connecting to the highly available Elasticsearch cluster. Currently you can view Kubernetes wide pod logs [here](http://188.166.135.10:5601/app/kibana#/dashboard/04dae180-336f-11e8-9f03-db5dae1ff024). Also you can filter the logs by pods in this dashboard.

![Kubernetes Wide Pod Logs](/dashboards/kibana/kubernetes-cluster-wide-pod-logs.png)


## Tear Down the Elasticsearch Cluster

### Delete the Helm Charts
```console
# Set an array in the terminal that contains chart directories
charts=(
  "elasticsearch"
  "fluentd"
  "kibana"
  "prometheus"
  "node-exporter"
  "kube-state-metrics"
  "grafana"
)

# Then execute the script to delete the charts
bash delete-all-charts.sh "${charts[@]}"
```

### Delete the Persistent Volume Claims

```console
kubectl delete persistentvolumeclaims \
            --namespace ha-elasticsearch-cluster \
            --selector app=elasticsearch
```

### Delete the Namespaces

```console
for namespace in "ha-elasticsearch-cluster" "kube-logging" "kube-monitoring"; do
    kubectl delete ns $namespace;
done
```

## References

- Elasticsearch, Setting the Heap Size https://www.elastic.co/guide/en/elasticsearch/reference/current/heap-size.html

- Elasticsearch, Node Discovery Settings https://www.elastic.co/guide/en/elasticsearch/reference/current/discovery-settings.html#unicast.hosts

- Elasticsearch, Virtual Memory Maximum MMap Count https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html#vm-max-map-count

- Elasticsearch, File Descriptors https://www.elastic.co/guide/en/elasticsearch/reference/current/file-descriptors.html#file-descriptors

- Kubernetes, Tolerating Node Failure https://kubernetes.io/docs/tutorials/stateful-application/zookeeper/#tolerating-node-failure
