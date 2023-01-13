#!/bin/bash

set -e

// UNSURE IF THIS WOULD BE THE SAME AS WE DONT SPLIT INTO TEKTONHELM AND REPOSITORYHELM ANYMORE

argocd app create galasa-release-tekton \
                  --project galasa \
                  --sync-policy auto \
                  --sync-option Prune=true \
                  --self-heal \
                  --repo https://github.com/galasa-dev/argocd \
                  --revision HEAD  \
                  --path tektonHelm \
                  --dest-server https://kubernetes.default.svc \
                  --dest-namespace galasa-release \
                  --helm-set branch=release \
                  --helm-set managersBranch=release
                  
argocd app create galasa-release-repo \
                  --project galasa \
                  --sync-policy auto \
                  --sync-option Prune=true \
                  --repo https://github.com/galasa-dev/argocd \
                  --revision HEAD  \
                  --path repositoryHelm \
                  --dest-server https://kubernetes.default.svc \
                  --dest-namespace galasa-release \
                  --helm-set branch=release 