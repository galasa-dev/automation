#!/bin/bash

set -e
                  
argocd app create galasa-release-repo \
                  --project default \
                  --sync-policy auto \
                  --sync-option Prune=true \
                  --repo https://github.com/galasa-dev/automation \
                  --revision HEAD  \
                  --path infrastructure/ibmcloud-galasadev-cluster/galasa-development/branch-maven-repository \
                  --dest-server https://kubernetes.default.svc \
                  --dest-namespace galasa-development \
                  --helm-set branch=release 