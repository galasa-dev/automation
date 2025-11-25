## How to install a Galasa service

Follow these steps if we ever need to migrate `galasa-service1` to a new Kubernetes cluster.

1. Install the `galasa-service1` namespace: `kubectl create namespace galasa-service1`
2. Apply the [admin-role.yaml](./admin-role.yaml): `kubectl apply -f admin-role.yaml -n galasa-service1`
3. Apply the [admin-service-account.yaml](./admin-service-account.yaml): `kubectl apply -f admin-service-account.yaml -n galasa-service1`
4. Apply the [secret-admin-token.yaml](./secret-admin-token.yaml): `kubectl apply -f secret-admin-token.yaml -n galasa-service1`
5. Create the GitHub OAuth app and put the Client ID and Client Secret in a Secrets Manager, so they can be extracted by an External Secret. See example in [secret-github-oauth-app.yaml](./secret-github-oauth-app.yaml)
6. Apply the [secret-github-oauth-app.yaml](./secret-github-oauth-app.yaml): `kubectl apply -f secret-github-oauth-app.yaml -n galasa-service1`

