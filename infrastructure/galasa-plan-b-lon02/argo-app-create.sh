#!/usr/bin/env bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#

# Where is this script executing from ?
BASEDIR=$(dirname "$0");pushd $BASEDIR 2>&1 >> /dev/null ;BASEDIR=$(pwd);popd 2>&1 >> /dev/null
# echo "Running from directory ${BASEDIR}"
export ORIGINAL_DIR=$(pwd)
cd "${BASEDIR}"

#--------------------------------------------------------------------------
# Set Colors
#--------------------------------------------------------------------------
bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr0)

red=$(tput setaf 1)
green=$(tput setaf 76)
white=$(tput setaf 7)
tan=$(tput setaf 202)
blue=$(tput setaf 25)

#--------------------------------------------------------------------------
#
# Headers and Logging
#
#--------------------------------------------------------------------------
underline() { printf "${underline}${bold}%s${reset}\n" "$@" ;}
h1() { printf "\n${underline}${bold}${blue}%s${reset}\n" "$@" ;}
h2() { printf "\n${underline}${bold}${white}%s${reset}\n" "$@" ;}
debug() { printf "${white}%s${reset}\n" "$@" ;}
info() { printf "${white}➜ %s${reset}\n" "$@" ;}
success() { printf "${green}✔ %s${reset}\n" "$@" ;}
error() { printf "${red}✖ %s${reset}\n" "$@" ;}
warn() { printf "${tan}➜ %s${reset}\n" "$@" ;}
bold() { printf "${bold}%s${reset}\n" "$@" ;}
note() { printf "\n${underline}${bold}${blue}Note:${reset} ${blue}%s${reset}\n" "$@" ;}

#-----------------------------------------------------------------------------------------                   
# Functions
#-----------------------------------------------------------------------------------------  

# Authenticate against ibm cloud first:
# ibmcloud login -a cloud.ibm.com -r eu-gb -g galasa-plan-b --sso
# ibmcloud ks cluster config --cluster ck61p5nl0u167uf76dag

# Now log into argocd... it uses the current kube/namespace.
# Switch to the argocd namespace.
# argocd login --core
# Check it works.
# argocd app list
# Or argocd login argocd.galasa.dev --sso  

cluster_name=$(basename ${BASEDIR})
info "Creating applications in cluster ${cluster_name}"

base_git_repo_path="infrastructure/${cluster_name}"

function create_application {
    app_name=$1
    repo_name=$2
    repo_path=$3

    h2 "Creating argocd application ${app_name}"

    argocd app create ${app_name} \
    --repo https://github.com/galasa-dev/automation.git \
    --path ${base_git_repo_path}/${repo_path} \
    --revision HEAD \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace galasa-development \
    --project default 
    rc=$? ; if [[ "${rc}" != "0" ]]; then error "Failed to create application ${app_name}. rc=${rc}" ; exit 1 ; fi

    cmd="argocd app sync ${app_name}"
    info "Command to run is $cmd"
    $cmd
    rc=$? ; if [[ "${rc}" != "0" ]]; then error "Failed to sync application ${app_name}. rc=${rc}" ; exit 1 ; fi
}

function create_helm_application {
    app_name=$1
    repo_path=$2
    values_file_relative_to_helm_chart=$3

    h2 "Creating argocd application ${app_name} from a helm chart"

    info "Using values file at ${values_file_path}"

    cmd="argocd app create ${app_name} \
    --repo https://github.com/galasa-dev/automation.git \
    --path ${base_git_repo_path}/${repo_path} \
    --revision HEAD \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace galasa-development \
    --project default"

    info "Command to run is $cmd"
    $cmd
    rc=$? ; if [[ "${rc}" != "0" ]]; then error "Failed to create application ${app_name}. rc=${rc}" ; exit 1 ; fi

    cmd="argocd app set ${app_name} --values ${values_file_relative_to_helm_chart}"
    info "Command to run is $cmd"
    $cmd
    rc=$? ; if [[ "${rc}" != "0" ]]; then error "Failed to set values into application ${app_name}. rc=${rc}" ; exit 1 ; fi

    cmd="argocd app sync ${app_name}"
    info "Command to run is $cmd"
    $cmd
    rc=$? ; if [[ "${rc}" != "0" ]]; then error "Failed to sync application ${app_name}. rc=${rc}" ; exit 1 ; fi
}

function delete_application {
    app_name=$1
    h2 "Deleting application ${app_name}"
    argocd app delete ${app_name} --cascade --yes
    rc=$? ; if [[ "${rc}" != "0" ]]; 
        then error "Failed to delete application ${app_name}. rc=${rc}. Continuing anyway..." 
    else
        success "Application ${app_name} deleted."
    fi
}

# delete_application "github-copyright"
# delete_application "codecov-maven-repos"
# delete_application "main-cli"
# delete_application "github-webhook-receiver"
# delete_application "main-maven-repos"
# delete_application "integration-maven-repos"
# delete_application "main-bld"
# delete_application "main-inttests"
# delete_application "main-simplatform"
# delete_application "galasa-development-namespace"
delete_application "galasa-ecosystem1"
create_application "galasa-ecosystem1" \
    https://github.com/galasa-dev/automation.git \
    "galasa-ecosystem1"

# delete_application "galasa-production"
# delete_application "galasa-production-namespace"

# create_application "galasa-development-namespace" \
#     https://github.com/galasa-dev/automation.git \
#     "galasa-development"

# create_application "main-cli" \
#     https://github.com/galasa-dev/automation.git \
#     "galasa-development/cli" 

# create_helm_application "codecov-maven-repos" \
#     "galasa-development/branch-maven-repository" \
#     "values-used-by-different-argo-apps/codecov-maven-repos.yaml"

# create_application "github-copyright" \
#     https://github.com/galasa-dev/automation.git \
#     "galasa-development/github-copyright"

# create_application "github-webhook-receiver" \
#     https://github.com/galasa-dev/automation.git \
#     "galasa-development/github-webhook-receiver"

# create_helm_application "integration-maven-repos" \
#     "galasa-development/branch-maven-repository" \
#     "values-used-by-different-argo-apps/integration-maven-repos.yaml"

# create_helm_application "main-maven-repos" \
#     "galasa-development/branch-maven-repository" \
#     "values-used-by-different-argo-apps/main-maven-repos.yaml"

# create_application "main-bld" \
#     https://github.com/galasa-dev/automation.git \
#     "galasa-development/galasabld" 

# create_application "main-inttests" \
#     https://github.com/galasa-dev/automation.git \
#     "galasa-development/inttests" 

# create_helm_application "main-simplatform" \
#     "galasa-development/simplatform" \
#     "values-used-by-different-argo-apps/main-simplatform-values.yaml"

# create_helm_application "prod-maven-repos" \
#     "galasa-development/branch-maven-repository" \
#     "values-used-by-different-argo-apps/prod-maven-repos.yaml"

# create_application "galasa-production-namespace" \
#     https://github.com/galasa-dev/automation.git \
#     "galasa-production"

# create_application "galasa-production" \
#     https://github.com/galasa-dev/automation.git \
#     "galasa-production/galasa-production"
