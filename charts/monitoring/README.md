# System

This chart is used to deploy dependencies that are needed to run other charts in this repo. It includes [keda](https://github.com/kedacore/keda) and [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) which are installed into the `keda` and `default` namespaces respectively.

## Installation

### Pre-requisites

- Kubernetes 1.12+
- Helm 3.0.0+

### Installing the Chart

```bash
helm repo add doublewordai https://doublewordai.github.io/helm-charts
helm repo update

kubectl create namespace monitoring

helm install system doublewordai/system -n monitoring --set "kube-prometheus-stack.prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=<name-of-storage-class-in-your-cluster>"
```

## Using the chart

The dependencies of this chart will enable you to add k8s objects to scale and monitor workloads. To tell Prometheus to scrape metrics from your `Service` you can deploy a `ServiceMonitor` CRD. To scale a `ReplicaSet` you can deploy a [`ScaledObject`](https://keda.sh/docs/concepts/scaling-deployments/) CRD to scale a workload based on metrics published to prometheus.
