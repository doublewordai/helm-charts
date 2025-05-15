# System Dependencies

This directory contains a [Helmfile](https://helmfile.readthedocs.io/en/latest/) containing all cluster wide dependencies needed run the [inference-stack](../charts/inference-stack/) or [console](../charts/console/) charts.

## Prerequisites

Before you begin, ensure you have the following installed:

- kubectl (version 1.18 or later)
- Helm (version 3.x)
- Helm diff plugin (optional, only required if running `helmfile apply`): [install guide](https://github.com/databus23/helm-diff?tab=readme-ov-file#install)

## Installation

1. **Install Operator Lifecycle Manager (OLM) into your cluster**

   Note: running this command will install resources into your active cluster.

   ```bash
   curl -L -s https://github.com/operator-framework/operator-controller/releases/latest/download/install.sh | bash -s
   ```

2. **Install Helmfile**

   Install Helmfile by following the instructions in the [official documentation](https://helmfile.readthedocs.io/en/latest/#installation).

   If using linux:

   ```bash
   mkdir -p /tmp/helmfile/ && \
      sudo wget -P /tmp/helmfile/ https://github.com/helmfile/helmfile/releases/download/v0.171.0/helmfile_0.171.0_linux_amd64.tar.gz && \
      sudo tar -xxf /tmp/helmfile/helmfile_0.171.0_linux_amd64.tar.gz -C /tmp/helmfile/ && \
      sudo mv /tmp/helmfile/helmfile /usr/local/bin && \
      sudo chmod +x /usr/local/bin/helmfile && \
      rm -rf /tmp/helmfile/
   ```

   or if using macOS:

   ```bash
   brew install helmfile
   ```

3. **Deploy with Helmfile**

   From this directory, run the following command to deploy all dependencies:

   ```bash
   PROMETHEUS_STORAGE_CLASS="<storage-class>" NVIDIA_TOOLKIT_VERSION="v1.17.5-ubi8" helmfile sync
   # `helmfile apply` can be used on a live cluster instead of `sync`: and will only apply changes.
   # The PROMETHEUS_STORAGE_CLASS environment variable must be supplied.
   # The NVIDIA_TOOLKIT_VERSION environment variable should be set to work with the nodes in your cluster.
   ```

   See `values.yaml` for configuration.

4. **Verify Deployments**

   After deployment, verify that all components are running:

   ```bash
   kubectl get all -n keda
   kubectl get all -n monitoring
   kubectl get all -n argocd
   kubectl get all -n inference-stack-operator-system
   ```

## Updating Dependencies

When developing the required versions of the helm charts referenced in the `helmfile` may change if you wish to upgrade the Inference Stack deployed in your cluster. To update the dependencies, run the following command:

```bash
# Get the latest helmfile.yaml
wget https://raw.githubusercontent.com/doublewordai/helm-charts/refs/heads/main/system/helmfile.yaml
# Sync to your cluster
helmfile repos && helmfile sync
# Or can run `helmfile apply` which will fetch from the repos, produce a diff and then sync.
```
