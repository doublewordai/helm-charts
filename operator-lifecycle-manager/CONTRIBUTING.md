# Contributing Guide

This is a guide for developers who want to edit and create new versions of the catalog, bundle, or Controller.

## Prerequisites

* Helm v3.x
* kubectl (version 1.18 or later)
* Operator Lifecycle Manager (OLM) v1

### Operator Lifecycle Manager (OLM)

```bash
curl -L -s https://github.com/operator-framework/operator-controller/releases/latest/download/install.sh | bash -s
```

This will create a [catalogd](https://operator-framework.github.io/operator-controller/project/olmv1_architecture/) manager and Controller manager in the `olmv1-system` namespace. As well as setup the CRDs needed for the OLM.

## Publishing

As you can see from the [architecture overview](./README.md#overview) we need to create catalog and bundle images in a container registry so they can be used in the cluster. We use the `docker.io/tytn` repositry to house all the images needed for the OLM. The following images are used:

* `tytn/operator`: the image that runs the Controller that holds the helm chart and a watcher config and resolves state.
* `tytn/operator-bundle`: the image that holds the resources that make up the Operator, in our case the `InferenceStack` Controller and the RBAC needed to run it.
* `tytn/operator-catalog`: the image that holds the catalog and the constructed manifests which are mounted in the catalog image.

For clarity we use the same semantic version for each of these images. We use a [Makefile](./Makefile) to build and push these images to the container registry. Run `make help` to see a list of available commands.

**Important**: Once you have created a new version you need to add it to the [changelog](../CHANGELOG.md#operator) noting it's supported CRD versions and some description of the changes.

### Operator Bundle

To create a new bundle you need to first build and push a new Operator image (the Controller).

1. Set the `VERSION` and `CRD_VERSION` in the Makefile if applicable. If you are creating a new version of the CRD you will need to make sure it is installed in the cluster and added to the [catalog helm chart](../../charts/catalog/README.md).

2. Create a new Operator bundle: this will create and push a new Operator image, and Operator bundle image using the current helm file.

```bash
make bundle-build-push
```

#### **IMPORTANT**: Versioning

The operators use semantic versioning and the CRD uses [Kubernetes API versioning scheme](https://kubernetes.io/docs/reference/using-api/#api-versioning). The semantic versioning of the Operator is crucial to make sure you don't break existing installations. We recommend Cluster Extensions are created subscribed to a major versioned channel (eg. `stable-v0`) and the OLM will choose the latest version in that channel to install. If you make a backwards incompatible change and only increment the minor version, when you update the `Catalog` in the cluster the OLM will automatically sync the newest Operator version and break existing `InferenceStacks`.

### Catalog

The cluster catalog contains all the available versions of our Inference Stack Operator. If you have created a new Operator bundle version you will need to edit the `./catalog/operator_catalog.yaml` file and add a new entry for your version.

* **NOTE:** It is best convention not to remove old versions from the catalog. If a user may have that specific version installed and if they upgrade will need to have the old version available to them.

```yaml
# This is the set of Operator bundles that we support in our catalog. To add another version of the Operator, add another bundle to the list.
Schema: olm.semver
GenerateMajorChannels: true
GenerateMinorChannels: false
# All new versions that we are confident in can be added to the fast channel, only mature releases should be added to the stable channel.
Stable:
  Bundles:
  - Image: docker.io/tytn/operator-bundle:0.1.0
  # Add your new version here like:
  # - Image: docker.io/tytn/operator-bundle:0.2.0
  # Note here we need the canonical image name.
Fast:
  Bundles:
  - Image: docker.io/tytn/operator-bundle:0.1.0
  # Add your new version here like:
  # - Image: docker.io/tytn/operator-bundle:0.2.0
  # Note here we need the canonical image name.
```

Once this is done you can push a new catalog image containing your new Operator:

```bash
make catalog-build-push
```

## Managing Operator Lifecycle

### Installing a Catalog

```bash
kubectl create namespace inference-stack-operator-system
helm repo add doublewordai https://doublewordai.github.io/helm-charts
helm install catalog doublewordai/catalog -n inference-stack-operator-system
```

### Upgrading a Catalog

Once a Catalog is running we can upgrade the version of the image the [Catalogd](README.md#catalogd) unpacks and caches by running:

```bash
helm upgrade catalog doublewordai/catalog -n inference-stack-operator-system --set "clusterCatalog.spec.source.image.ref=docker.io/tytn/operator-catalog:<desired-version>"
```

Note that the image reference should be the canonical image name.

### Installing a New Operator Bundle

Once the cluster catalog is correctly installed, you can install operators using the `ClusterExtension` Custom Resource provided by OLM.

```yaml
apiVersion: olm.operatorframework.io/v1
kind: ClusterExtension
metadata:
  name: inference-stack-operator-v0-stable
spec:
  namespace: inference-stack-operator-system # namespace to deploy the Operator into
  source:
    sourceType: Catalog # source type to use: https://operator-framework.github.io/operator-controller/api-reference/operator-controller-api-reference/#sourceconfig
    catalog:
      # catalog filter: https://operator-framework.github.io/operator-controller/api-reference/operator-controller-api-reference/#catalogfilter
      packageName: inference-stack-operator # name of the Operator
      channels: [ "stable-v0" ] # channels to subscribe to
```

The OLM will then attempt to install all the non-skipped versions of the Operator in the stable channel we have provided in the `ClusterCatalog`. We can also add the `/spec/source/catalog/version` field to fix the installation to a specific version. If not provided, the OLM will install the latest version in the channel.

If a `ClusterExtension` exists and is set to install from a major versioned channel (eg. `stable-v0`), when a newer bundle is added to the `ClusterCatalog` the OLM will automatically update the Operator to the latest version in the channel.

This can also be done by upgrading the `catalog` helm chart with the cluster extensions set in the `values.yaml` file.

```bash
helm upgrade catalog doublewordai/catalog -n inference-stack-operator-system --set "clusterExtensions[0].spec.source.catalog.version=<desired-version>" --values values.yaml
```

where values.yaml should look like:

```yaml
# This section is for the cluster extensions that describe how to deploy the Operator. More information can be found here: https://operator-framework.github.io/operator-controller/api-reference/operator-controller-api-reference/#clusterextension
clusterExtension:
  enabled: true
  versions:
  - name: inference-stack-operator-stable-v0
    annotations: {}
    spec:
      namespace: inference-stack-operator-system # namespace to deploy the Operator into
      source:
        sourceType: Catalog # source type to use: https://operator-framework.github.io/operator-controller/api-reference/operator-controller-api-reference/#sourceconfig
        catalog:
          # catalog filter: https://operator-framework.github.io/operator-controller/api-reference/operator-controller-api-reference/#catalogfilter
          packageName: inference-stack-operator # name of the operator
          channels: [ "stable-v0" ] # channels to subscribe to
```

You can choose to omit the version field and let the OLM manage installing the latest version in the channel.

### Using a Specific Operator Version

When you install the `InferenceStack` CR you need to specify the major version of the Operator you want to reconcile the CR. This is done by setting the `operatorVersion` label on the CR.

```yaml
apiVersion: doublewordai.co/v1alpha1
kind: InferenceStack
metadata:
  name: my-inference-stack
  labels:
    operatorVersion: v2 # This is the major version of the Operator you want to reconcile this CR
spec:
  applications:
    hello-world:
      nodeSelector:
        nvidia.com/gpu.product: NVIDIA-GeForce-RTX-3060
      readerConfig:
        modelName: "unsloth/Llama-3.2-1B-Instruct"
        device: cuda
  imagePullSecrets:
    - name: regcred
```

If you do not specify the `operatorVersion` label the OLM then none of the operators will reconcile the CR. We use only the major version and enforce semantic versioning for the Operators, so the OLM can install patch and minor updates without needing to update the `InferenceStack` CR.

### Uninstalling an Operator

To uninstall an Operator you can delete the `ClusterExtension` Custom Resource, this will remove the Operator from the Cluster:

```bash
kubectl delete clusterextension inference-stack-operator-v0-stable
```
