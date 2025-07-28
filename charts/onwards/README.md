# Onwards

A Rust-based AI Gateway that provides a unified interface for routing requests to openAI compatible targets. Deploys the [onwards](https://github.com/doublewordai/onwards) binary as a Kubernetes deployment, as well as a service to expose the API and optional ingresses/additional services.

## TL;DR

```bash
helm repo add doublewordai https://doublewordai.github.io/helm-charts
helm install onwards doublewordai/onwards
```
