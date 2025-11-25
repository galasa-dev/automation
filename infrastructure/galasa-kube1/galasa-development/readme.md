## How to install the galasa-development namespace resources

Note: Files in this folder are deployed to the cluster by ArgoCD.


## Pre-install

1. Create the `galasa-development` namespace: `kubectl create namespace galasa-development`
2. Create the secret `secret-api-key` which lets the `galasa-development` namespace use the IBM Cloud Secrets Manager. The secret should already exist in the `argocd` namespace. 
   - Option 1: `kubectl get secret secret-api-key -n argocd -o yaml | sed 's/namespace: .*/namespace: galasa-development/' | kubectl apply -f - ` 
   - Option 2: Get the secret's value using the Kubernetes extension, and copy it into this command: `kubectl -n galasa-development create secret generic secret-api-key --from-literal=apikey=<secret-value>`
3. Add an annotation to the `secret-api-key` secret that means it won't get pruned by ArgoCD: `kubectl get secret secret-api-key -n galasa-development -o yaml | sed 's/annotations:$/annotations:\n    argocd.argoproj.io\/sync-options: Prune=false/' | kubectl apply -f -`


## Install the ArgoCD apps that deploy the development download sites

For this you will use the ArgoCD CLI, so you will need to get the CLI token you configured for ArgoCD and set it as an environment variable in your terminal.

1. Look up the value of the `kube1-argocd-cli-token` secret and put it into the `ARGOCD_CLI_TOKEN` environment variable: `export ARGOCD_CLI_TOKEN=<TOKEN>`
<!-- 2. Set the ArgoCD server as an environment variable: `export ARGOCD_SERVER="argocd.galasa.dev"` -->
2. Set the ArgoCD server as an environment variable: `export ARGOCD_SERVER=argocd.galasa-kube1-d2e8765deb38dddd0aa1b649462cf87f-0000.eu-gb.containers.appdomain.cloud`
3. Log into the ArgoCD server with the CLI: `argocd login $ARGOCD_SERVER --auth-token $ARGOCD_CLI_TOKEN --grpc-web --sso`

```

# 1. Create app galasa-development-namespace

argocd app create galasa-development-namespace \
--repo https://github.com/galasa-dev/automation.git \
--path infrastructure/galasa-kube1/galasa-development \
--dest-namespace galasa-development \
--dest-server https://kubernetes.default.svc \
--auth-token $ARGOCD_CLI_TOKEN \
--server $ARGOCD_SERVER \
--grpc-web

# 2. Create app main-maven-repos

argocd app create main-maven-repos \
--repo https://github.com/galasa-dev/automation.git \
--path infrastructure/galasa-kube1/galasa-development/branch-maven-repository \
--dest-namespace galasa-development \
--dest-server https://kubernetes.default.svc \
--auth-token $ARGOCD_CLI_TOKEN \
--server $ARGOCD_SERVER \
--grpc-web

# 3. Create app main-cli

argocd app create main-cli \
--repo https://github.com/galasa-dev/automation.git \
--path infrastructure/galasa-kube1/galasa-development/cli \
--dest-namespace galasa-development \
--dest-server https://kubernetes.default.svc \
--auth-token $ARGOCD_CLI_TOKEN \
--server $ARGOCD_SERVER \
--grpc-web

# 4. Create app main-bld

argocd app create main-bld \
--repo https://github.com/galasa-dev/automation.git \
--path infrastructure/galasa-kube1/galasa-development/galasabld \
--dest-namespace galasa-development \
--dest-server https://kubernetes.default.svc \
--auth-token $ARGOCD_CLI_TOKEN \
--server $ARGOCD_SERVER \
--grpc-web

# 5. Create app main-inttests

argocd app create main-inttests \
--repo https://github.com/galasa-dev/automation.git \
--path infrastructure/galasa-kube1/galasa-development/inttests \
--dest-namespace galasa-development \
--dest-server https://kubernetes.default.svc \
--auth-token $ARGOCD_CLI_TOKEN \
--server $ARGOCD_SERVER \
--grpc-web

# 6. Create app main-ivts

argocd app create main-ivts \
--repo https://github.com/galasa-dev/automation.git \
--path infrastructure/galasa-kube1/galasa-development/ivts \
--dest-namespace galasa-development \
--dest-server https://kubernetes.default.svc \
--auth-token $ARGOCD_CLI_TOKEN \
--server $ARGOCD_SERVER \
--grpc-web

# 7. Create app main-simplatform

argocd app create main-simplatform \
--repo https://github.com/galasa-dev/automation.git \
--path infrastructure/galasa-kube1/galasa-development/simplatform \
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