# Highly Available Elasticsearch on to of Kubernetes

## Karsilasilabilecek Hatalar ve Notlar

- Split brain
    - At a high-level, "split-brain" is what arises when one or more nodes can't communicate with the others, and several "split" masters get elected. 
    - To learn more consult to https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-node.html#split-brain
    - discover.zen.minimum_master_nodes can be set to => N/2 + 1

- Headless service
    -  Does not perform load balancing or have a static IP

- A Kubernetes StatefulSet allows you to assign a stable identity to Pods and grant them stable, persistent storage.

- Statefulsetteki pod'lara erismek icin es-cluster-[0,1,2].elasticsearch.kube-logging.svc.cluster.local

- Statefulsetteki The .spec.selector.matchLabels and .spec.template.metadata.labels fields must match.

- Heap size https://www.elastic.co/guide/en/elasticsearch/reference/current/heap-size.html

- discovery.zen.ping.unicast.hosts https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-discovery.html

- https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html#_notes_for_production_use_and_defaults

- increase-fd-ulimit, which runs the ulimit command to increase the maximum number of open file descriptors. To learn more about this step, consult the 

- kac replica calistiracagini belirt
    - eger local'de calistiracaksan replica sayisi kadar persistent volume yarat.

- Dockerfile'i kendin yazmak ?
- Username password koymak ?
- readinessProbe && livenessProbe
- resource quota
- mustafa akin'in az bilinen kubernetes objeleri article'i
- imagePullPolicy: "IfNotPresent" => image pull policy yazacak misin ?
- kubernetes ve docker versiyonlarini yaz.
- Digitalocean'a gecince servisleri LoadBalancer yapabilirsin.
- kibana ve grafana'ya authentication mekanizmasi koyabilirsin.
- senin monitoring yaml'larini kube-prometheus ile karsilastir.
- jaeger
- 9300 portu ne ise yariyor bak
- butun docker image'larini gozden gecir.
- do'da daha kucuk makinelere gecilebilir.
- rollback icin script
- imagepullpolicy
- label indentation
- node exporter'da hostNetwork: true vs.
- monitoring elemanlarindaki label'lari degistirdim, calisiyor mu bir bak.
- daemonset icin toleration tanimi ?
- dry-run debug'i sil

https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html#_notes_for_production_use_and_defaults
## Installation

You can execute the following in your terminal to deploy highly available elasticsearch cluster to the kubernetes:

```console
$ kubectl apply -f kubernetes-manifests/elasticsearch
```
Then verify the installation by executing the following:

```console
$ kubectl get pods -n ha-elasticsearch-cluster -o wide -w
```

Accessing the Elasticsearch cluster via its rest api can be done by using kubectl port forward. Execute the following to do so;
```console
$ kubectl port-forward ha-elasticsearch-0 9200:9200 -n ha-elasticsearch-cluster
```
Then curl the endpoint with the following command;

```console
$ curl -XGET http://localhost:9200/_cluster/stats?pretty
```

## Tearing Down
To delete the elasticsearch cluster you can execute the following commands in your terminal;

```console
$ kubectl delete -f kubernetes-manifests/elasticsearch/statefulset.yaml
$ kubectl delete pvc elasticsearch-volume-ha-elasticsearch-0
$ kubectl delete pvc elasticsearch-volume-ha-elasticsearch-1
$ kubectl delete pvc elasticsearch-volume-ha-elasticsearch-2
$ kubectl delete -f kubernetes-manifests/elasticsearch/persistent-volume.yaml
$ kubectl delete -f kubernetes-manifests/elasticsearch/service.yaml
```

### High Availability - Tolerating Node Failure

Normally more than one Statefulset pods may locate in the same Kubernetes host. If more than one instance of the Elasticsearch cluster in the same Kubernetes host, and this host fails end users may experince an outage until the pods rescheduled in another host or host become available. 
To prevent such an outage we can schedule all of the pods of the StatefulSet to the different Kubernetes hosts. To do so, I have added the following part to the Elasticsearch Statefulset manifest;

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

We can check the node names for our pods
```console
    for i in 0 1 2; 
    do 
        kubectl get pod ha-elasticsearch-$i --template {{.spec.nodeName}}; echo "";
    done
```

Also I have created PodDisruptionBudget to indicate that at most one pod from the Elasticsearch StatefulSet can be unavailable at any time.
### Testing the High Availability

## References
- https://kubernetes.io/docs/tutorials/stateful-application/zookeeper/#tolerating-node-failure (TODO: kaldirilabilir)


http://prometheus-service.kube-monitoring.svc.cluster.local:9200


### Monitoring

toollarin detaylarindan basitce bahset.

- Prometheus
- Kube state metrics
- Node exporter
- Grafana (Grafana gelince data source ekle, dashboard import et.)

### Logging && Debugging

- Fluentd
- Kibana (kibana gelince dashboard import et.)
- debug case'ini gostermek icin sacma islemler yapabilirsin. (orn grafanada data source'u yanlis girme, elasticsearch'e yanlis istek atma.)


### Helm ?


### Backup


### Zero down time deployment


Currently I am using free plan on DigitalOcean, the urls are temporary, I may provide different urls if we decide to proceed to the next interview.