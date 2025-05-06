# Retrieval Augmented Generation (RAG)

This chart encapsulates the RAG (Retrieval Augmented Generation) system.

## TL;DR

```bash
helm repo add doublewordai https://doublewordai.github.io/helm-charts
helm install rag doublewordai/rag
```

### Pulling Console images

To access the Console images you need to make sure you are authenticated to pull from the Doubleword DockerHub. To do this encode your docker auth into a k8s Secret. You can then make this accessible to k8s in your values.yaml file, so it can pull the container images:

```yaml
imagePullSecrets:
  - name: <SECRET_NAME>
```

## Installation

You need to first create a secret with the following values:

```yaml
# rag-secret.yaml
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: rag-secret
data:
  RAG_APP_PASSWORD: admin
  RAG_APP_USERNAME: password
  MONGODB_CONNECTION_STRING: xxxx
  MONGODB_PASSWORD: xxxxx
  GITHUB_TOKEN: token
  INTERNAL_DATABASE_USER: postgres
  INTERNAL_DATABASE_PASSWORD: password
```

```bash
kubectl apply -f rag-secret.yaml
```

Then when you install the chart you can pass the secret name as a value:

```bash
helm install rag . --set "secret.name=<secret-name>"
```
