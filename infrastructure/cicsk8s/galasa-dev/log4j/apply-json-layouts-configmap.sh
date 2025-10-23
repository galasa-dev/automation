#!/usr/bin/env bash
#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#
#-----------------------------------------------------------------------------------------
#
# Objectives: Creates/Updates the Log4j JSON templates ConfigMap called 'galasa-log4j-json-templates' 
# used by the prod1 service. The ConfigMap contains the GalasaLogsLayout.json file, so this script 
# should be run to apply any changes made to that JSON layout file.
#
# Make sure that your kubectl context is pointing at the internal Kubernetes cluster that prod1 is
# available on.
#
#-----------------------------------------------------------------------------------------

# Where is this script executing from ?
BASEDIR=$(dirname "$0");pushd $BASEDIR 2>&1 >> /dev/null ;BASEDIR=$(pwd);popd 2>&1 >> /dev/null
export ORIGINAL_DIR=$(pwd)

cd "${BASEDIR}/.."
WORKSPACE_DIR=$(pwd)

#-----------------------------------------------------------------------------------------
#
# Set Colors
#
#-----------------------------------------------------------------------------------------
bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr0)
red=$(tput setaf 1)
green=$(tput setaf 76)
white=$(tput setaf 7)
tan=$(tput setaf 202)
blue=$(tput setaf 25)

#-----------------------------------------------------------------------------------------
#
# Headers and Logging
#
#-----------------------------------------------------------------------------------------
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

function check_if_kubectl_is_installed {
    h1 "Checking if kubectl is installed..."
    which kubectl
    rc=$?
    if [[ "${rc}" != "0" ]]; then
        info "kubectl is not installed. Install it and try again."
        exit 1
    fi
    success "kubectl is installed!"
}

function apply_json_template_configmap {
    configmap_name="galasa-log4j-json-templates"
    json_template_file="${BASEDIR}/GalasaLogsLayout.json"
    h1 "Applying Log4j JSON template ConfigMap from file ${json_template_file}..."

    kubectl create configmap ${configmap_name} \
    --namespace galasa-dev \
    --from-file ${json_template_file} \
    -o yaml \
    --dry-run=client | kubectl apply -f -

    rc=$?
    if [[ "${rc}" != "0" ]]; then
        info "Failed to apply ConfigMap ${configmap_name}. rc=${rc}"
        exit 1
    fi

    success "ConfigMap ${configmap_name} updated successfully!"
}

#-----------------------------------------------------------------------------------------
# Main logic
#-----------------------------------------------------------------------------------------

check_if_kubectl_is_installed
apply_json_template_configmap