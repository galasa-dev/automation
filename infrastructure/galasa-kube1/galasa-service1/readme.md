# Galasa services

The Galasa services installed on the galasa-kube1 cluster are deployed via a blue/green deployment strategy.

## Blue/Green Kubernetes Resources

The following resources are in place to support blue/green deployments:

- `galasa-service-gateway` - A Kubernetes Gateway resource that is used to access the "main" Galasa service that is currently being served.
- `galasa-blue-green-httproute` - A Kubernetes HTTPRoute resource that is used to route traffic to the blue or green Galasa service.

## Switching between Blue and Green Deployments

To switch between blue and green deployments, you will need to update the [`galasa-blue-green-httproute` resource](./galasa-service-parent-gateway.yaml) to point to the desired Galasa service using the following steps:

1. Update the service name for the `/dex` path to point to the Dex service for your new deployment.
2. Update the service name for the `/api` path to point to the API service for your new deployment.
3. Update the hostname for the web UI redirect to point to the web UI for your new deployment.

To get the names of your new deployment's Kubernetes services, run:

```
kubectl get svc
```

## How to install a Galasa service

Follow these steps if we ever need to migrate `galasa-service1` to a new Kubernetes cluster.

1. Install the `galasa-service1` namespace: `kubectl create namespace galasa-service1`
2. Apply the [admin-role.yaml](./admin-role.yaml): `kubectl apply -f admin-role.yaml -n galasa-service1`
3. Apply the [admin-service-account.yaml](./admin-service-account.yaml): `kubectl apply -f admin-service-account.yaml -n galasa-service1`
4. Apply the [secret-admin-token.yaml](./secret-admin-token.yaml): `kubectl apply -f secret-admin-token.yaml -n galasa-service1`
5. Create the GitHub OAuth app and put the Client ID and Client Secret in a Secrets Manager, so they can be extracted by an External Secret. See example in [secret-github-oauth-app.yaml](./secret-github-oauth-app.yaml)
6. Apply the [secret-github-oauth-app.yaml](./secret-github-oauth-app.yaml): `kubectl apply -f secret-github-oauth-app.yaml -n galasa-service1`

