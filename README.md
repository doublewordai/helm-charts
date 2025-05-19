# Doubleword Inference Platform Helm Charts

The DoubleWord Inference Platform provides helm charts allow you to deploy open source AI on Kubernetes at any scale.

## Project Structure

```bash
charts/
├── catalog/                    # Cluster Catalog, `InferenceStack` Custom Resource Definition (CRD) and Cluster Extensions.
├── console/                    # Console UI, an empty `InferenceStack` Custom Resource which the UI can manipulate.
├── inference-stack/            # Gateway, and numerous Readers.
└── monitoring/                 # Custom configuration of the kube-prometheus-stack helm chart provided by the Prometheus Community.
system/                         # Step-by-step guide to install all the cluster wide dependencies needed to run the inference-stack or console charts.
operator-lifecycle-manager/     # Resources to build Inference Stack Operator Lifecycle Manager.
```

## Architecture

### Overview

The Inference Stack revolves around a Custom Resource Definition (CRD) called the `InferenceStack`. We create object representation for our desired state and have an Operator that reconcile. Below is a high level overview of the architecture:

![overview](overview.png)

The Controller in this context is a sub-component of the Operator that watches the Custom Resource `InferenceStack`. We create this Controller/Operator with the [system installation](./system/README.md#installation) which is a one off cluster wide step-up. If you are looking for more information about the Inference Stack Operator Lifecycle, see the [conceptual](./operator-lifecycle-manager/README.md) and [contributing guides](./operator-lifecycle-manager/CONTRIBUTING.md).

## Getting Started

1. *If installing Doubleword Inference Platform for the first time* - follow the steps in the [system docs](./system/README.md#installation) to install the system dependencies.
2. Install the [console](./charts/console/README.md) helm chart, access the console UI to edit and view your stack.

## Glossary

* Cluster: a group of computing nodes, or worker machines, that run containerized applications, managed by a control plane that orchestrates and manages the cluster's resources and workloads.

* Console: a management interface that allows users to manipulate `InferenceStacks`. It also can be used for observability of the Readers.

* Custom Resource Definition: a kubernetes object that extends the Kubernetes API and is available for use in the cluster.

* [Helm Operator](https://github.com/operator-framework/helm-operator-plugins): an open source Operator from the [Operator Framework](https://operatorframework.io/) project.

* `InferenceStack`: the custom resource that we deploy which has the configuration for each application that the user wants to be reconciled by the Inference Stack Operator.

* Controller: a set of objects that are responsible to transforming a custom resource into a set of kubernetes native objects. Any custom resource that is deployed in the cluster is managed by an Operator.

* Operator: the combination of a Custom Resource Definition and a Controller. They follow a "reconciliation loop" pattern where they:
  * Observe the current state
  * Compare it to the desired state
  * Take actions to align the two
  * Watch for changes

* [Operator Lifecycle Manager (OLM)](https://operator-framework.github.io/operator-controller/): a tool that helps install, update, and manage the lifecycle of all Operators and their associated services running across their clusters.

* Cluster Catalog: a curated collections of Kubernetes extensions, such as Operators. Cluster administrators can enable polling to get over-the-air updates to `clusterCatalogs` when extension authors publish changes such as bug fixes and new features.

* Cluster Extension: components that expand the Kubernetes API without modifying its source code. Some examples of extensions are Operators, Custom Resource Definitions (CRDs), and Service Meshes.

* Gateway: the entrypoint into the Inference Stack, it receives all requests to individual models and routes them to the correct queue exposed by a server.

* Reader: an individual model that is running in the Inference Stack. It connects to the server of the Gateway to pull requests and process them.

* Consumer Group: the group of collective Readers that pull from a single queue. Note, Readers can belong to more than one consumer group, so there is a many-to-many mapping between Readers and Queues.

....

