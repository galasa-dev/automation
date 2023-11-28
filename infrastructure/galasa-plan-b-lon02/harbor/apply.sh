#!/usr/bin/env bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#

# Applies all the yaml in this folder to the current IKS cluster.

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

# Namespace is gained from the folder name.
export namespace=$(basename ${BASEDIR})

function apply_yaml_files {

    h2 "Applying resources to the namespace $namespace"

    # Create a list of all the yaml files we want to create.
    yaml_file_names=($(ls *.yaml))

    rc="0"

    for key in "${!yaml_file_names[@]}"
    do
    yaml_file_name=${yaml_file_names[$key]}
    info "File to apply: $yaml_file_name"

    if [[ "${rc}" != "0" ]]; then
        warn "Skipping $yaml_file_name"
    else
        kubectl apply -f $yaml_file_name -n $namespace
        rc=$?
        if [[ "${rc}" != "0" ]]; then
            error "Failed to apply the yaml file $yaml_file_name to namespace $namespace"
        else 
            success "Applied file $yaml_file_name to namespace $namespace OK"
        fi 
    fi
    done

    if [[ "${rc}" != "0" ]]; then
    exit 1
    fi

    success "Applied all yaml files from folder $BASEDIR OK"
}

function rollout_restart {
  h2 "Restarting the deployments... waiting for 120secs."
  kubectl rollout restart -n ${namespace} deployments --timeout=120s \
    harbor-core \
    harbor-jobservice \
    harbor-portal \
    harbor-registry
  if [[ "${rc}" != "0" ]]; then
    error "Failed to re-start all the deployments"
    exit 1
  fi
  success "Re-started the deployments OK"
}

apply_yaml_files
rollout_restart


