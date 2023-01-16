#!/bin/bash

set -e

argocd app create cli-release-repo \
                  --project default \
                  --sync-policy auto \
                  --sync-option Prune=true \
                  --self-heal \
                  --repo https://github.com/galasa-dev/cli \
                  --revision HEAD  \
                  --path infrastructure/ibmcloud-galasadev-cluster/galasa-development/cli \
                  --dest-server https://kubernetes.default.svc \
                  --dest-namespace galasa-development \
                  --helm-set branch=release 