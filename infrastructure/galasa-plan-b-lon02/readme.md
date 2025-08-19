# Galasa-plan-b-lon02 Kubernetes cluster


## Deployed applications
This cluster has the following applications set up:

- [argocd](https://argocd.galasa-plan-b-lon02-3fdc13787e8248a7d32fa4e5af5b0294-0000.eu-gb.containers.appdomain.cloud)
- [cert-manager](https://cert-manager.io)
- [ingress-nginx](https://kubernetes.github.io/ingress-nginx)

## Notes about this cluster

- Argocd has a dex server built-in.
- There is no secrets service on this account. It's on the CIO account, and we use the same secrets manager service.

# Create argocd applications
Create applications in argocd using the `argo-app-create.sh` script.

> Read + Change it before you run it.

# cert-manager
cert-manager has been installed into the cluster using Helm, and it lives in the `cert-manager` namespace.

To install cert-manager (version v1.18.2 at the time of writing), run:

```
helm install \
  cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --version v1.18.2 \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true
```

## Issuing a certificate using Helm

The [cert-installer](https://github.com/galasa-dev/helm/tree/main/charts/cert-installer) Helm chart exists to automate the installation of `Issuer` and `Certificate` resources on Kubernetes. See the chart's [README](https://github.com/galasa-dev/helm/blob/main/charts/cert-installer/README.md) for instructions on how to use it.

Namespaces in which cert-installer has been installed in:

- argocd
- galasa-ecosystem1
- galasa2

## Issuing a certificate manually

1. Create an `Issuer` resource (or a `ClusterIssuer` for cluster-wide certificate issuing), for example:

```yaml
# This is a namespaced Issuer resource that requests certificates to be issued from the Let's Encrypt
# staging issuer. The staging issuer should be used for development and testing purposes only.
# 
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    # The ACME server URL
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: user@example.com
    # The ACME certificate profile
    profile: tlsserver
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-staging
    # Enable the HTTP-01 challenge provider
    solvers:
      - http01:
          ingress:
            ingressClassName: nginx
```

2. Create a `Certificate` resource:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-certificate
spec:
  # The name of the TLS secret to be created
  # for use in Ingress TLS definitions
  secretName: my-cert-secret
  dnsNames:
  - example.com
  issuerRef:
    # The Issuer that you would like to use to issue
    # this certificate
    name: letsencrypt-staging
    kind: Issuer

```
