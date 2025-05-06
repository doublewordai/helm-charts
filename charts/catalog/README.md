# Catalog

This is all the resource needed to create a Catalog containing the `InferenceStack` Operator, from the [Operator Lifecycle Manager](https://operator-framework.github.io/operator-controller/) project. We have a [high level overview](../../operator-lifecycle-manager/README.md#overview) of the OLM architecture, in which this deploys a `ClusterCatalog` CR, an `InferenceStack` CRD, and Role Based Access Control (RBAC) resources. It also optionally creates a `ClusterExtension` CR which subscribes and installs a specific version of the Operator available in the catalog from a specific channel.

## TL;DR

```bash
helm repo add doublewordai https://doublewordai.github.io/helm-charts
helm install catalog doublewordai/catalog
```

To see how to create new Operators and Catalog images see [here](../../operator-lifecycle-manager/CONTRIBUTING.md#publishing).

## Installing Extensions

Cluster Extensions should be installed and fixed to a major channel. We have two channels available: `stable` and `fast`, and the channel names are created by appending `-vX` where `X` is the major version of the Operator you want to use. The `stable` channel is for production ready versions of the Operator, and the `fast` channel is for the latest versions of the Operator. The `fast` channel is not recommended for production use.

Here's an example of a configuration that installs an Operator tracking the newest v0 bundles in the `stable` channel:

```yaml
# This section is for the cluster extensions that describe how to deploy the operator. More information can be found here: https://operator-framework.github.io/operator-controller/api-reference/operator-controller-api-reference/#clusterextension
clusterExtension:
  enabled: false
  versions:
  - name: inference-stack-operator-stable-v0
    annotations: {}
    spec:
      namespace: inference-stack-operator-system # namespace to deploy the operator into
      source:
        sourceType: Catalog # source type to use: https://operator-framework.github.io/operator-controller/api-reference/operator-controller-api-reference/#sourceconfig
        catalog:
          # catalog filter: https://operator-framework.github.io/operator-controller/api-reference/operator-controller-api-reference/#catalogfilter
          packageName: inference-stack-operator # name of the operator
          channels: [ "stable-v0" ] # channels to subscribe to
```

It is not recommended to have more than one cluster extension that tracks the same major Operator even if in different channels. This is because we differentiate the Operator that should be used to resolve the `InferenceStack` CR by the `operatorVersion` label which takes the form of `vX` where `X` is the major version of the Operator. If you have more than one Operator with the same major version, more than one Operator will try to reconcile the `InferenceStack` CR which will cause conflicts.
