# Management Console

The management console is a simple & intuitive interface for creating, managing, and monitoring your LLM deployments.

## TL;DR

```bash
helm repo add doublewordai https://doublewordai.github.io/helm-charts
helm install console doublewordai/console
```

### Pulling Console images

To access the Console images you need to make sure you are authenticated to pull from the TitanML DockerHub. To do this encode your docker auth into a k8s Secret. You can then make this accessible to k8s in your values.yaml file, so it can pull the container images:

```yaml
imagePullSecrets:
  - name: <SECRET_NAME>
```

Alternatively you can achieve it like so:

```bash
helm install console doublewordai/console --set imagePullSecrets[0].name=<SECRET_NAME>
```

## Configuration & installation details

## Architecture overview

This chart deploys the management console as two Kubernetes [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) (one for the frontend, one for the backend), a [postgres](https://www.postgresql.org/) database, and a [`InferenceStack` custom resource](https://github.com/doublewordai/helm-charts/charts/inference-stack) which is managed by the [Inference Stack Operator](./../../operator-lifecycle-manager/README.md).
Authentication for the database-backend connection defaults to the values in templates/secret.yaml.

To provide a custom secret (with `dbUser` and `dbPassword` keys), provide `--set secret.generate=false --set secret.name="my-secret"`.

## Resource requests & limits

This chart sets no resource requests or limits for the components.
In a production environment, these should be set.

## Single sign on (SSO)

### Microsoft Azure / Entra

#### Create a configuration for the application

In the Azure Portal, configure the Directory.   Choose 'Manage', 'App registrations', then 'New Registration':

| Field name              | Expected value                                             |
| ----------------------- | ---------------------------------------------------------- |
| Name                    | Doubleword Console                                         |
| Supported account types | Accounts in this organizational directory only             |
| Redirect URI Platform   | Web                                                        |
| Redirect URI            | https://doubleword.yourdomain.example/authentication/auth  |
                          
The Redirect URI does not have to be publically accessible.

#### Create a client secret

Configure the application.  Click 'Manage', 'Certificates & secrets', 'Client secets', then 'New client secret':

| Field name  | Expected value                   |
| ----------- | -------------------------------- |
| Description | doubleword-console-client-secret |
| Expires     | 180 days                         |

Click 'Add', then record the 'Value' and the 'Secret ID' to use later.

#### Helm chart values

Click 'Manage', 'App Registrations', 'Endpoints' and use the displayed information to complete these values in `values.yaml`:

```
authentication:
  sso:
    publicAccess: false
    authUrl: 'OAuth 2.0 authorization endpoint (v2)' in the 'Endpoints'
    tokenUrl: 'OAuth 2.0 token endpoint (v2)' in the 'Endpoints'
    fqdn: Fully qualified hostname from the Redirect URI specified above (for example:  *doubleword.yourdomain.example*)
    provider: "azure"
    clientId: 'Application (client) ID' in the 'App Registration'
    clientSecret: This is the 'Value' part of the client secret above
```

#### Testing

Go to *https://doubleword.yourdomain.example*

Assuming the configuration is correct, it will redirect to the Microsoft sign in page. After signing in, Microsoft will redirect back to the application.

#### Debugging

Add to the `values.yaml`:

```
debug:
  enabled: true
```

Then visit *https://doubleword.yourdomain.example/debug*

The response should contain a `X-Doubleword-User` header containing the email address of the user.






