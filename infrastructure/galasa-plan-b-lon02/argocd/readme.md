## Warning !

Note : Only apply these yamls once ! Argocd edits them on the fly.

- Apply argocd only once
- Then you can deploy argocd-cm
- Then all of the secrets files

If you need to refresh the secret files, you have to delete them first. 

## Useful commands 

```
kubectl delete -f infrastructure/galasa-plan-b-lon02/argocd/secret-argocd.yaml
kubectl delete -f infrastructure/galasa-plan-b-lon02/argocd/secrets-manager.yaml

kubectl apply -f infrastructure/galasa-plan-b-lon02/argocd/secrets-manager.yaml
kubectl apply -f infrastructure/galasa-plan-b-lon02/argocd/secret-argocd.yaml
```

```
kubectl get ExternalSecrets  
```

```
kubectl rollout restart -n argocd deployments argocd-applicationset-controller argocd-dex-server argocd-notifications-controller argocd-redis argocd-repo-server argocd-server
```

## After installation
- create connections to github repositories
  - Log in using the admin account
  - Settings -> Repositories -> Add Github repo using HTTPS 
  - Add https://github.com/galasa-dev/helm.git
  - Add https://github.com/galasa-dev/automation.git
  
- Allocate a CLI token for the automation to use to contact argocd
  - name example: planb-argocd-cli-token
  - Log in using the admin account
  - Settings -> Accounts -> select Galasa account -> allocate new CLI token
