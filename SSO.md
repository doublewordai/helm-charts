
# Configuring SSO

## Microsoft Azure / Entra

### Create a configuration for the application

In the Azure Portal, configure the Directory.   Choose 'Manage', 'App registrations', then 'New Registration':

| Field name              | Expected value                                             |
| ----------------------- | ---------------------------------------------------------- |
| Name                    | Doubleword Console                                         |
| Supported account types | Accounts in this organizational directory only             |
| Redirect URI Platform   | Web                                                        |
| Redirect URI            | https://doubleword.yourdomain.example/authentication/auth  |
                          
The Redirect URI does not have to be publically accessible.

### Create a client secret

Configure the application.  Click 'Manage', 'Certificates & secrets', 'Client secets', then 'New client secret':

| Field name  | Expected value                   |
| ----------- | -------------------------------- |
| Description | doubleword-console-client-secret |
| Expires     | 180 days                         |

Click 'Add', then record the 'Value' and the 'Secret ID' to use later.

### Helm chart values

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

### Testing

Go to *https://doubleword.yourdomain.example*

Assuming the configuration is correct, it will redirect to the Microsoft sign in page. After signing in, Microsoft will redirect back to the application.

### Debugging

Add to the `values.yaml`:

```
debug:
  enabled: true
```

Then visit *https://doubleword.yourdomain.example/debug*

The response should contain a `X-Doubleword-User` header containing the email address of the user.






