# Doubleword Inference Platform Helm Charts

The DoubleWord Inference Platform provides helm charts allow you to deploy open source AI on Kubernetes at any scale.

## Project Structure

```bash
charts/
├── rag/                        # Document processor which connects to an external vector database and provides a REST API for RAG queries.
├── console/                    # Console UI, an empty `InferenceStack` Custom Resource which the UI can manipulate.
├── inference-stack/            # Gateway, and numerous Readers.
└── observability/              # Custom configuration of the kube-prometheus-stack helm chart provided by the Prometheus Community for Doubleword AI deployments.
```
