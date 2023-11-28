## Notes

Files in this folder are deployed to the cluster by argocd.

## Before you create the application

### create the secret which lets anything pull secrets from the IBM cloud secrets manager.
- Create the namespace
- Move the secret into the namespace... it should already exist in the `argocd` namespace.
```
kubectl get secret secret-api-key -n argocd -o yaml | sed 's/namespace: .*/namespace: galasa-development/' | kubectl apply -f - 
```

### Allow the secret to exist without being pruned by argocd:
```
kubectl get secret secret-api-key -n galasa-development -o yaml | sed 's/annotations:$/annotations:\n    argocd.argoproj.io\/sync-options: Prune=false/' | kubectl apply -f -
```

## Create the argocd application 

### Using the command-line (incomplete so far)

The `secret-argocd.yaml` file contains a reference to a secret `planb-argocd-cli-token`

Look up the value of that secret and put it into the `ARGOCD_CLI_TOKEN` environment variable.
```

export ARGOCD_SERVER="argocd.galasa.dev"

argocd login $ARGOCD_SERVER --auth-token $ARGOCD_CLI_TOKEN --grpc-web

argocd app create galasa-development-namespace \
--repo https://github.com/galasa-dev/automation.git \
--path infrastructure/galasa-plan-b-lon02/galasa-development \
--dest-namespace galasa-development \
--dest-server https://kubernetes.default.svc \
--auth-token $ARGOCD_CLI_TOKEN \
--server $ARGOCD_SERVER \
--grpc-web
```

Note: The `--directory-recurse` option is missing, so only files in this folder are deployed.

## Useful commands
```
kubectl get secret secret-api-key -n default -o yaml | sed 's/namespace: .*/namespace: galasa-development/' | kubectl apply -f -

kubectl get SecretStore -n galasa-development
kubectl get ExternalSecrets -n galasa-development
```