

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