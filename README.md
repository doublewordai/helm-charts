# Doubleword Inference Platform Helm Charts

The DoubleWord Inference Platform provides helm charts allow you to deploy open source AI on Kubernetes at any scale.

## Project Structure

```bash
charts/
├── onwards/                    # a rust based AI Gateway that provides a unified interface for routing requests to openAI compatible targets.
├── rag/                        # Document processor which connects to an external vector database and provides a REST API for RAG queries.
├── console/                    # Console UI, an empty `InferenceStack` Custom Resource which the UI can manipulate.
├── debug/                      # Debug pod with reverse SSH tunnel capabilities and comprehensive RBAC permissions for debugging remote Kubernetes clusters.
└── observability/              # Custom configuration of the kube-prometheus-stack helm chart provided by the Prometheus Community for Doubleword AI deployments.
```
