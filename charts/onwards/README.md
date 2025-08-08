# Onwards

A Rust-based AI Gateway that provides a unified interface for routing requests to openAI compatible targets. Deploys the [onwards](https://github.com/doublewordai/onwards) binary as a Kubernetes deployment, as well as a service to expose the API and optional ingresses/additional services.

## TL;DR

```bash
helm repo add doublewordai https://doublewordai.github.io/helm-charts
helm install onwards doublewordai/onwards
```

## Configuration

The Onwards binary is configured using a ConfigMap that is mounted into the container. You can customize the configuration by modifying the `values.yaml` file in the Helm chart:

```yaml
# Onwards configuration, see https://github.com/doublewordai/onwards?tab=readme-ov-file#quickstart for more information.
targets:
  generate:
    enabled: true
    url: "http://doubleword-router-service.takeoff"
    model: "google/gemma-3-12b-it"
```

## Metrics

The onwards binary exposes a metrics port by default on port `9090`. You can configure this in the `values.yaml` file of the Helm chart:

```yaml
metrics:
  # false by default
  enabled: true
  # Port to expose metrics on - default is 9090
  port: 9090
  # Prefix to use for metrics - default is 'onwards'
  prefix: "onwards"
```

This relies on the prometheus Custom Resource Definition (CRD) being installed which you can do by installing the [kube-prometheus-stack](https://github.com/prometheus-operator/kube-prometheus) or the [Doubleword Observability chart](../observability/README.md).
