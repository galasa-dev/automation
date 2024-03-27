#!/bin/bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#
#-----------------------------------------------------------------------------------------                   
#
# Objectives: Creates an argocd application which does some mysterious things... what ?
#
# Environment variable over-rides:
# 
#-----------------------------------------------------------------------------------------                   


function ask_user_for_release_type {
    PS3="Select the type of release process please: "
    select lng in release pre-release
    do
        case $lng in
            "release")
                export release_type="release"
                break
                ;;
            "pre-release")
                export release_type="prerelease"
                break
                ;;
            *)
            echo "Unrecognised input.";;
        esac
    done
    echo "Chosen type of release process: ${release_type}"
}

function create-maven-repos {           
    argocd app create ${release_type}-maven-repos \
                    --project default \
                    --sync-policy auto \
                    --sync-option Prune=true \
                    --repo https://github.com/galasa-dev/automation \
                    --revision HEAD  \
                    --path infrastructure/galasa-plan-b-lon02/galasa-development/branch-maven-repository \
                    --dest-server https://kubernetes.default.svc \
                    --dest-namespace galasa-development \
                    --helm-set wrapping.branch=${release_type} \
                    --helm-set wrapping.imageTag=${release_type} \
                    --helm-set wrapping.deploy=true \
                    --helm-set gradle.branch=${release_type} \
                    --helm-set gradle.imageTag=${release_type} \
                    --helm-set gradle.deploy=true \
                    --helm-set maven.branch=${release_type} \
                    --helm-set maven.imageTag=${release_type} \
                    --helm-set maven.deploy=true \
                    --helm-set framework.branch=${release_type} \
                    --helm-set framework.imageTag=${release_type} \
                    --helm-set framework.deploy=true \
                    --helm-set extensions.branch=${release_type} \
                    --helm-set extensions.imageTag=${release_type} \
                    --helm-set extensions.deploy=true \
                    --helm-set managers.branch=${release_type} \
                    --helm-set managers.imageTag=${release_type} \
                    --helm-set managers.deploy=true \
                    --helm-set obr.branch=${release_type} \
                    --helm-set obr.imageTag=${release_type} \
                    --helm-set obr.deploy=true \
                    --helm-set javadoc.branch=${release_type} \
                    --helm-set javadoc.imageTag=${release_type} \
                    --helm-set javadoc.deploy=true \
                    --helm-set javadocsite.branch=${release_type} \
                    --helm-set javadocsite.imageTag=${release_type} \
                    --helm-set javadocsite.deploy=true \
                    --helm-set restApiDocSite.branch=${release_type} \
                    --helm-set restApiDocSite.imageTag=${release_type} \
                    --helm-set restApiDocSite.deploy=true \
                    --helm-set isolated.branch=${release_type} \
                    --helm-set isolated.imageTag=${release_type} \
                    --helm-set isolated.deploy=true \
                    --helm-set mvp.branch=${release_type} \
                    --helm-set mvp.imageTag=${release_type} \
                    --helm-set mvp.deploy=true 
}
function create-cli {   
    argocd app create ${release_type}-cli \
                    --project default \
                    --sync-policy auto \
                    --sync-option Prune=true \
                    --self-heal \
                    --repo https://github.com/galasa-dev/automation \
                    --revision HEAD  \
                    --path infrastructure/galasa-plan-b-lon02/galasa-development/cli \
                    --dest-server https://kubernetes.default.svc \
                    --dest-namespace galasa-development \
                    --helm-set branch=${release_type} \
                    --helm-set imageTag=${release_type}
}
# checks if it's been called by 01-run-pre-release.sh, if it isn't run all functions
if [[ "$CALLED_BY_PRERELEASE" == "" ]]; then
    ask_user_for_release_type
    set -e
    create-maven-repos
    create-cli
fi
