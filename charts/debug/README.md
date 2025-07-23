# Debug Pod Helm Chart

This Helm chart deploys a debug pod with reverse SSH tunnel capabilities and comprehensive RBAC permissions for debugging remote Kubernetes clusters.

## Features

- **Debug Pod**: Ubuntu-based container with debugging tools pre-installed
- **Reverse SSH Tunnel**: Establishes a reverse SSH connection to a bastion host
- **Cluster Access**: Full RBAC permissions for debugging cluster resources
- **Pre-installed Tools**: kubectl, helm, curl, wget, jq, and SSH client/server
- **Persistent Connection**: Keeps the pod running indefinitely for debugging sessions

## Prerequisites

- Kubernetes cluster
- Helm 3.x
- Access to a bastion host (for SSH tunneling)
- SSH key pair for bastion host authentication

## Installation

### Basic Installation (without SSH tunnel)

```bash
helm install debug-pod ./debug -n debug-namespace --create-namespace
```

### Installation with SSH Tunnel

1. Create SSH key secret:
```bash
kubectl create secret generic debug-ssh-key \
  --from-file=ssh-privatekey=/path/to/your/private/key \
  -n debug-namespace
```

2. Install with SSH configuration:
```bash
helm install debug-pod ./debug -n debug-namespace --create-namespace \
  --set ssh.bastionHost=your-bastion-server.com \
  --set ssh.bastionUser=your-username \
  --set ssh.bastionPort=22
```

## Configuration

### SSH Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ssh.bastionHost` | SSH server hostname/IP of the bastion host | `""` |
| `ssh.bastionPort` | SSH server port on the bastion host | `22` |
| `ssh.bastionUser` | SSH username for the bastion host | `""` |
| `ssh.localPort` | Local port to bind for reverse tunnel | `2222` |
| `ssh.remotePort` | Remote port on bastion to forward to | `22` |
| `ssh.privateKeySecret` | Name of secret containing SSH private key | `"debug-ssh-key"` |

### RBAC Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `rbac.create` | Create RBAC resources | `true` |
| `rbac.clusterRole.rules` | RBAC rules for the debug pod | See values.yaml |

### Pod Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Container image repository | `ubuntu` |
| `image.tag` | Container image tag | `22.04` |
| `debug.sleepInfinity` | Keep pod running indefinitely | `true` |
| `debug.installTools` | Install debugging tools | `true` |

## Usage

### Accessing the Debug Pod

1. **Exec into the pod:**
```bash
kubectl exec -it -n debug-namespace deployment/debug-pod -- /bin/bash
```

2. **Check available tools:**
```bash
kubectl version --client
helm version
curl --version
```

### SSH Tunnel Access

If SSH tunnel is configured, you can access the debug pod from your bastion host:

```bash
# From bastion host
ssh root@localhost -p 22
# Default password: debug123
```

### Common Debugging Tasks

1. **List all pods in cluster:**
```bash
kubectl get pods --all-namespaces
```

2. **Check cluster nodes:**
```bash
kubectl get nodes -o wide
```

3. **Examine cluster resources:**
```bash
kubectl get all --all-namespaces
```

4. **Debug networking:**
```bash
curl -v http://service-name.namespace.svc.cluster.local
```

## Security Considerations

⚠️ **Warning**: This debug pod has elevated privileges and cluster-wide access. Use only in development/testing environments.

- The pod runs as root with privileged security context
- It has cluster-wide RBAC permissions
- SSH server is enabled with a default password
- Only deploy in trusted environments

## Customization

### Adding Custom Tools

You can add custom tools by mounting a ConfigMap with installation scripts:

```yaml
volumes:
  - name: custom-tools
    configMap:
      name: debug-tools-script
      defaultMode: 0755

volumeMounts:
  - name: custom-tools
    mountPath: /custom-tools
```

### Custom RBAC Rules

Modify the RBAC rules in `values.yaml` to restrict or expand permissions:

```yaml
rbac:
  clusterRole:
    rules:
      - apiGroups: [""]
        resources: ["pods"]
        verbs: ["get", "list"]
```

## Troubleshooting

### SSH Tunnel Issues

1. **Check SSH key secret:**
```bash
kubectl get secret debug-ssh-key -n debug-namespace
```

2. **Check pod logs:**
```bash
kubectl logs -n debug-namespace deployment/debug-pod
```

3. **Verify bastion connectivity:**
```bash
kubectl exec -n debug-namespace deployment/debug-pod -- ssh -o ConnectTimeout=5 user@bastion-host
```

### RBAC Issues

1. **Check service account:**
```bash
kubectl get serviceaccount -n debug-namespace
```

2. **Verify cluster role binding:**
```bash
kubectl get clusterrolebinding | grep debug
```

## Uninstallation

```bash
helm uninstall debug-pod -n debug-namespace
kubectl delete namespace debug-namespace
```
