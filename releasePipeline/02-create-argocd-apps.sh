#!/bin/bash

set -e
                  
argocd app create release-maven-repos \
                  --project default \
                  --sync-policy auto \
                  --sync-option Prune=true \
                  --repo https://github.com/galasa-dev/automation \
                  --revision HEAD  \
                  --path infrastructure/ibmcloud-galasadev-cluster/galasa-development/branch-maven-repository \
                  --dest-server https://kubernetes.default.svc \
                  --dest-namespace galasa-development \
                  --helm-set wrapping.branch=release \
                  --helm-set wrapping.imageTag=release \
                  --helm-set wrapping.deploy=true \
                  --helm-set gradle.branch=release \
                  --helm-set gradle.imageTag=release \
                  --helm-set gradle.deploy=true \
                  --helm-set maven.branch=release \
                  --helm-set maven.imageTag=release \
                  --helm-set maven.deploy=true \
                  --helm-set framework.branch=release \
                  --helm-set framework.imageTag=release \
                  --helm-set framework.deploy=true \
                  --helm-set extensions.branch=release \
                  --helm-set extensions.imageTag=release \
                  --helm-set extensions.deploy=true \
                  --helm-set managers.branch=release \
                  --helm-set managers.imageTag=release \
                  --helm-set managers.deploy=true \
                  --helm-set obr.branch=release \
                  --helm-set obr.imageTag=release \
                  --helm-set obr.deploy=true \
                  --helm-set javadoc.branch=release \
                  --helm-set javadoc.imageTag=release \
                  --helm-set javadoc.deploy=true \
                  --helm-set javadocsite.branch=release \
                  --helm-set javadocsite.imageTag=release \
                  --helm-set javadocsite.deploy=true \
                  --helm-set restApiDocSite.branch=release \
                  --helm-set restApiDocSite.imageTag=release \
                  --helm-set restApiDocSite.deploy=true \
                  --helm-set eclipse.branch=release \
                  --helm-set eclipse.imageTag=release \
                  --helm-set eclipse.deploy=true \
                  --helm-set p2.branch=release \
                  --helm-set p2.imageTag=release \
                  --helm-set p2.deploy=true \
                  --helm-set isolated.branch=release \
                  --helm-set isolated.imageTag=release \
                  --helm-set isolated.deploy=true \
                  --helm-set mvp.branch=release \
                  --helm-set mvp.imageTag=release \
                  --helm-set mvp.deploy=true 

argocd app create release-cli \
                  --project default \
                  --sync-policy auto \
                  --sync-option Prune=true \
                  --self-heal \
                  --repo https://github.com/galasa-dev/automation \
                  --revision HEAD  \
                  --path infrastructure/ibmcloud-galasadev-cluster/galasa-development/cli \
                  --dest-server https://kubernetes.default.svc \
                  --dest-namespace galasa-development \
                  --helm-set branch=release \
                  --helm-set imageTag=release                   