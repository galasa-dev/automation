#!/bin/bash

set -e

argocd app create cli-release-repo \
                  --project galasa \
                  --sync-policy auto \
                  --sync-option Prune=true \
                  --self-heal \
                  --repo https://github.com/galasa-dev/cli \
                  --revision HEAD  \
                  --path argocd/repositoryHelm \
                  --dest-server https://kubernetes.default.svc \
                  --dest-namespace galasa-release \
                  --helm-set branch=release 