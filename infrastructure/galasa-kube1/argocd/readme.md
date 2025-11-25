## How to install ArgoCD

### Useful pages:

- https://argocd-operator.readthedocs.io/en/latest/usage/dex/

### Installation instructions

1. Follow the instructions on the ArgoCD [docs](https://argo-cd.readthedocs.io/en/stable/operator-manual/user-management/#1-register-the-application-in-the-identity-provider) and create a new OAuth application on GitHub [here](https://github.com/organizations/galasa-dev/settings/applications/new). Ensure to take note of the Client ID and Client Secret.
2. Use the Client ID and Client Secret from the OAuth app to create a Kubernetes Secret with two fields: `dex.github.clientid` and `dex.github.clientsecret`. See [secret-argocd.yaml](secret-argocd.yaml).
3. Create a namespace `argocd`: `kubectl create namespace argocd`
4. Apply [argocd.yaml](./argocd.yaml) **once** into the `argocd` namespace: `kubectl apply -f argocd.yaml -n argocd`
5. Apply [argocd-cm.yaml](./argocd-cm.yaml) into the `argocd` namespace: `kubectl apply -f argocd-cm.yaml -n argocd`
6. Apply [argocd-ingress.yaml](./argocd-ingress.yaml) into the `argocd` namesapce: `kubectl apply -f argocd-ingress.yaml -n argocd`
7. Apply [argocd-rbac-cm.yaml](./argocd-rbac-cm.yaml) into the `argocd` namesapce: `kubectl apply -f argocd-rbac-cm.yaml -n argocd`
8. Apply [argocd-ssh-known-hosts-cm.yaml](./argocd-ssh-known-hosts-cm.yaml) into the `argocd` namesapce: `kubectl apply -f argocd-ssh-known-hosts-cm.yaml -n argocd`
9. Ensure all Pods are running and healthy: `kubectl get pods -n argocd`
10. Go to your ArgoCD URL in a browser and test that you can log in with the Dex OAuth app.


## After installation
1. Create connections to the GitHub repositories:
  - Log in using the admin account/personal account through OAuth
  - Go to 'Settings' -> 'Repositories' -> 'Connect repo using HTTPS'
  - Add https://github.com/galasa-dev/helm.git
  - Add https://github.com/galasa-dev/automation.git
  
2. Allocate a CLI token for the automation to use to contact ArgoCD
  - Log in using the admin account/personal account through OAuth
  - Go to 'Settings' -> 'Accounts' -> select the 'galasa' account -> under 'Tokens', click 'Generate New'
  - Copy the token and put it in the Secrets Manager and anywhere the automation needs to access it


## Useful commands 

If you need to refresh the secret files, you have to delete them first:

```
kubectl delete -f infrastructure/galasa-kube1/argocd/secret-argocd.yaml
kubectl delete -f infrastructure/galasa-kube1/argocd/secrets-manager.yaml

kubectl apply -f infrastructure/galasa-kube1/argocd/secrets-manager.yaml
kubectl apply -f infrastructure/galasa-kube1/argocd/secret-argocd.yaml
```

```
kubectl get ExternalSecrets  
```

```
kubectl rollout restart -n argocd deployments argocd-applicationset-controller argocd-dex-server argocd-notifications-controller argocd-redis argocd-repo-server argocd-server
```
