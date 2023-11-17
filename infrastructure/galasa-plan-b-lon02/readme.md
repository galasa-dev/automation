# Galasa-plan-b-lon02 Kubernetes cluster


## Deployed applications
This cluster has the following applications set up:

- [argocd](https://argocd.galasa-plan-b-lon02-3fdc13787e8248a7d32fa4e5af5b0294-0000.eu-gb.containers.appdomain.cloud)



## Notes about this cluster

- Argocd has a dex server built-in.
- There is no secrets service on this account. It's on the CIO account, and we use the same secrets manager service.

# Create argocd applications
Create applications in argocd using the `argo-app-create.sh` script.

> Read + Change it before you run it.