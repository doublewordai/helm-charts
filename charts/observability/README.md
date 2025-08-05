# Alerts

This is a supplementary chart for the [kube-prometheus-stack](https://github.com/prometheus-operator/kube-prometheus) that provides alerting capabilities, custom dashboards. It configures alert manager and Prometheus rules to monitor the health of your Doubleword AI deployments.

## TL;DR

```bash
helm repo add doublewordai https://doublewordai.github.io/helm-charts
helm install observability doublewordai/observability
```

## Secrets

There are two secrets that are required for the alerting system to notify you of issues:

* `slack-webhook`: Slack webhook URL for alert notifications
* `incident-io-webhook`: Incident.io webhook URL for alert notifications

These can be created using the following commands:

```bash
kubectl create secret generic slack-webhook --from-literal=url=<your-slack-webhook-url> --namespace monitoring
kubectl create secret generic incident-io-webhook --from-literal=url=<your-incident-io-webhook-url> --from-literal=token=<your-incident-io-token> --namespace monitoring
```

## Metric Persistence

To ensure that metrics are persisted across restarts, you can configure a persistent volume claim (PVC) for Prometheus. This done by default, but you can customize it in the `values.yaml` file to use your own storage class or settings.

```bash
helm install observability doublewordai/observability --set kube-prometheus-stack.prometheus.prometheusSpec.volumeClaimTemplate.spec.storageClassName="your-storage-class"
```

You can also overwrite its name with the following flag:

```bash
--set kube-prometheus-stack.prometheus.prometheusSpec.volumeClaimTemplate.metadata.name="your-pvc-name"
```
