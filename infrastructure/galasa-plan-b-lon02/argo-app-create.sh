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


cluster_name=$(basename ${BASEDIR})
info "Creating applications in cluster ${cluster_name}"

base_git_repo_path="infrastructure/${cluster_name}"

function create_application {
    app_name=$1
    repo_path=$2

    argocd app create ${app_name} \
    --repo https://github.com/galasa-dev/automation.git \
    --path ${base_git_repo_path}/${repo_path} \
    --revision HEAD \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace galasa-development \
    --project default 
    rc=$? ; if [[ "${rc}" != "0" ]]; then error "Failed to create application ${app_name}. rc=${rc}" ; exit 1 ; fi
}

function create_helm_application {
    app_name=$1
    repo_path=$2
    values_file=$3

    h2 "Creating argocd application ${app_name} from a helm chart"

    values_file_path="${base_git_repo_path}/${values_file}"

    info "Using values file at ${values_file_path}"

    cmd="argocd app create ${app_name} \
    --repo https://github.com/galasa-dev/automation.git \
    --path ${base_git_repo_path}/${repo_path} \
    --revision HEAD \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace galasa-development \
    --project default \
    --values ${values_file_path}"

    info "Command to run is $cmd"

    $cmd

    rc=$? ; if [[ "${rc}" != "0" ]]; then error "Failed to create application ${app_name}. rc=${rc}" ; exit 1 ; fi
}

function delete_application {
    app_name=$1
    h2 "Deleting application ${app_name}"
    argocd app delete ${app_name} --cascade --yes
    rc=$? ; if [[ "${rc}" != "0" ]]; then error "Failed to delete application ${app_name}. rc=${rc}" ; exit 1 ; fi
}

# delete_application "codecov-maven-repos"

create_helm_application "codecov-maven-repos" \
"galasa-development/branch-maven-repository" \
"galasa-development/branch-maven-repository/values-used-by-different-argo-apps/codecov-maven-repos.yaml"

# create_application "github-copyright" "galasa-development/github-copyright"
# create_application "github-webhook_receiver" "galasa-development/github-copyright"
# create_helm_application "integration-maven-repos" "galasa-development/branch-maven-repository"





