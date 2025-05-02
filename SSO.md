
# Configuring SSO

## Microsoft Azure / Entra

### Create a configuration for the application

In the Azure Portal, configure the Directory.   Choose 'Manage', 'App registrations', then 'New Registration':

*Name*
Doubleword Console

*Supported account types*
Accounts in this organizational directory only (Default Directory only - Single tenant)

*Redirect URI Platform*
Web

*Redirect URI*
https://doubleword.yourdomain.example/authentication/auth
This address does not have to be publically accessible, but Microsoft will redirect the user here after authentication

### Create a client secret

Configure the application.  Click 'Manage', 'Certificates & secrets', 'Client secets', then 'New client secret':

*Description*
doubleword-console-client-secret

*Expires*
180 days

Record the 'Value' and the 'Secret ID'.

### Helm chart values

Click 'Manage', 'App Registrations', 'Endpoints' and use the displayed information to complete the values below:

`
authentication:
  sso:
    publicAccess: false
    authUrl: 'OAuth 2.0 authorization endpoint (v2)' in the 'Endpoints'
    tokenUrl: 'OAuth 2.0 token endpoint (v2)' in the 'Endpoints'
    fqdn: Fully qualified hostname from the Redirect URI specified above (for example:  *doubleword.yourdomain.example*)
    provider: "azure"
    clientId: 'Application (client) ID' in the 'App Registration'
    clientSecret: This is the 'Value' part of the client secret above
`

### Testing

Go to *https://doubleword.yourdomain.example*

Assuming the configuration is correct, it will redirect to the Microsoft sign in page. After signing in, Microsoft will redirect back to the application.

### Debugging

Add to the values.yaml:

`
debug:
  enabled: true
`
Then visit *https://doubleword.yourdomain.example/debug*

The response should contain an X-Doubleword-User response containing the email address of the user






