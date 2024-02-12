#!/usr/bin/env bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#

# Applies all the yaml in this folder to the current IKS cluster.



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
debug() { printf "[ ] ${white}%s${reset}\n" "$@" ;}
info() { printf "[${white}➜] %s${reset}\n" "$@" ;}
success() { printf "[${green}✔${reset}] ${green}%s${reset}\n" "$@" ;}
error() { printf "[${red}✖${reset}]${red} %s${reset}\n" "$@" ;}
warn() { printf "[${tan}➜${reset}] ${tan}%s${reset}\n" "$@" ;}
bold() { printf "${bold}%s${reset}\n" "$@" ;}
note() { printf "\n${underline}${bold}${blue}Note:${reset} ${blue}%s${reset}\n" "$@" ;}


# Where is this script executing from ?
function locate_this_script() {
    h1 "Finding out where this script is executing from"
    BASEDIR=$(dirname "$0");pushd $BASEDIR 2>&1 >> /dev/null ;BASEDIR=$(pwd);popd 2>&1 >> /dev/null
    # echo "Running from directory ${BASEDIR}"
    export ORIGINAL_DIR=$(pwd)
    cd "${BASEDIR}"
    info "BASEDIR is $BASEDIR"
    info "Current folder is $PWD"
    success "OK"
}

#--------------------------------------------------
function find_kube_namespace() {
    h1 "Finding the kubernetes namespace... based on the path to get to this script."
    export kube_namespace=$(basename $( cd ${BASEDIR}/.. ; pwd ))
    info "Kubernetes namespace to use is $kube_namespace"
    success "OK"
}

#--------------------------------------------------
function check_env_vars_are_set() {
    h1 "Checking that environment variables are set."

    h2 "Checking HARBOR_ADMIN_PASSWORD environment variable."
    if [[ "$HARBOR_ADMIN_PASSWORD" == "" ]]; then
        info "environment variable has not been set by caller. Using a random value instead"
        export HARBOR_ADMIN_PASSWORD=$(openssl rand -hex 12 | head -c 16)
    fi
    success "Once installed, the admin password will be $HARBOR_ADMIN_PASSWORD"

    h2 "Checking RANDOM_16_CHAR_STRING_USED_FOR_ENCRYPTION environment variable."
    if [[ "$RANDOM_16_CHAR_STRING_USED_FOR_ENCRYPTION" == "" ]]; then
        info "environment variable RANDOM_16_CHAR_STRING_USED_FOR_ENCRYPTION has not been set. Creating a random value to use instead"
        export RANDOM_16_CHAR_STRING_USED_FOR_ENCRYPTION=$(openssl rand -hex 12 | head -c 16)
    fi
    success "RANDOM_16_CHAR_STRING_USED_FOR_ENCRYPTION is $RANDOM_16_CHAR_STRING_USED_FOR_ENCRYPTION OK"

    h2 "Checking HARBOR_VERSION environment variable"
    if [[ "$HARBOR_VERSION" == "" ]]; then
        info "environment variable HARBOR_VERSION has not been set. Using default instead."
        export HARBOR_VERSION="v2.9.2"
    fi
    success "HARBOR_VERSION is $HARBOR_VERSION OK"
    
}

#--------------------------------------------------
function uninstall_harbor() {
    h1 "Uninstalling the existing harbor install."
    helm uninstall harbor
    rc=$? ; if [[ "$rc" != "0" ]]; then error "Failed to uninstall harbor using helm!. rc=$rc" ; exit 1 ; fi

    # Wait for all the pods to disappear...
    export is_done="not-done"
    while [[ "$is_done" == "not-done" ]]; do
        kubectl get pods -n $kube_namespace | grep "harbor"
        
        rc=$?
        if [[ "$rc" == "0" ]]; then 
            info "There are still harbor pods to remove. Waiting"
            sleep 2
        else
            info "All the harbor pods are gone. Good."
            export is_done="done"
        fi
    done

    # Remove the PV claims to clean up...
    kubectl delete pvc data-harbor-redis-0 data-harbor-trivy-0 database-data-harbor-database-0 harbor-jobservice harbor-registry
    rc=$? ; if [[ "$rc" != "0" ]]; then error "Failed to remove the PV claims!. rc=$rc" ; exit 1 ; fi

    success "Harbor fully removed. OK"
}

#--------------------------------------------------
function flush_temp_folder() {
    h1 "Flushing the temporary folder"
    rm -fr ${BASEDIR}/temp
    rc=$? ; if [[ "$rc" != "0" ]]; then error "Failed to flush the temporary folder contents!. rc=$rc" ; exit 1 ; fi
    success "OK"
}

#--------------------------------------------------
function create_temp_folder() {
    h1 "Create a temporary folder"
    mkdir -p temp
    cd ${BASEDIR}/temp
    rc=$? ; if [[ "$rc" != "0" ]]; then error "Failed to move to the temporary folder!. rc=$rc" ; exit 1 ; fi
    success "OK"
}

#--------------------------------------------------
function clone_harbor_helm_chart_github_repo() {
    h1 "Clone the github repo"
    git clone git@github.com:goharbor/harbor-helm.git
    rc=$? ; if [[ "$rc" != "0" ]]; then error "Failed to clone the harbor helm chart github repository!. rc=$rc" ; exit 1 ; fi
    success "OK"
}

#--------------------------------------------------
function make_sure_harbor_isnt_already_installed() {
    h1 "Removing the existing helm install of harbor"
    helm list | grep "harbor"
    rc=$? 
    if [[ "$rc" == "0" ]]; then 
        info "Harbor is installed using helm. Removing it" 

        uninstall_harbor
    else
        info "Harbor is not installed using helm already. No need to remove it."
    fi
    success "OK"
}

#--------------------------------------------------
function customise_helm_chart() {
    h1 "Customizing the helm chart with our own stuff"

    # We have doctored parts of the helm chart to make it work.
    # Which means replacing some of the template files...
    info "Copying some customised files into the helm chart... to over-ride the existing things."
    cp $BASEDIR/database-ss.yaml.template $BASEDIR/temp/harbor-helm/templates/database/database-ss.yaml
    rc=$? ; if [[ "$rc" != "0" ]]; then error "Failed to copy the database over-ridden files into the helm chart templates!. rc=$rc" ; exit 1 ; fi

    cp $BASEDIR/redis-statefulset.yaml.template $BASEDIR/temp/harbor-helm/templates/redis/statefulset.yaml
    rc=$? ; if [[ "$rc" != "0" ]]; then error "Failed to copy the redis over-ridden files into the helm chart templates!. rc=$rc" ; exit 1 ; fi

    success "OK"
}

#--------------------------------------------------
function substitute_value() {
    marker_to_substitute="$1"
    value_to_inject="$2"
    info "substituting-in value for marker $marker_to_substitute..."

    cat $BASEDIR/temp/harbor-helm/values.yaml | sed "s/$marker_to_substitute/$value_to_inject/g" > $BASEDIR/temp/values-temp.yaml
    cp $BASEDIR/temp/values-temp.yaml $BASEDIR/temp/harbor-helm/values.yaml

    rm -f $BASEDIR/temp/values-temp.yaml
    success "marker $marker_to_substitute value is set into values.yaml file OK"
}

#--------------------------------------------------
function customise_helm_values() {
    h1 "Constructing the values.yaml file to contain some secrets, in readiness to use in the install."
    # We want to inject some secret values into the helm install based on environment variable values.
    cp $BASEDIR/values.yaml.template $BASEDIR/temp/harbor-helm/values.yaml
    rc=$? ; if [[ "$rc" != "0" ]]; then error "Failed to the over-ridden values.yaml into the helm chart folder!. rc=$rc" ; exit 1 ; fi

    substitute_value "@@HARBOR_ADMIN_PASSWORD@@" "$HARBOR_ADMIN_PASSWORD"

    substitute_value "@@RANDOM_16_CHAR_STRING_USED_FOR_ENCRYPTION@@" "$RANDOM_16_CHAR_STRING_USED_FOR_ENCRYPTION"

    substitute_value "@@HARBOR_VERSION@@" "$HARBOR_VERSION"

    substitute_value "@@HARBOR_KUBE_NAMESPACE@@" "$kube_namespace"

    substitute_value "@@HARBOR_INGRESS_ENTRY_HOST@@" "harbor.galasa.dev"
    success "OK"
}

#--------------------------------------------------
function install_harbor_using_helm() {
    h1 "Installing harbor using the customized helm chart and values.."
    cd $BASEDIR/temp/harbor-helm
    helm install harbor ./ -f $BASEDIR/temp/harbor-helm/values.yaml
    rc=$? ; if [[ "$rc" != "0" ]]; then error "Helm install failed!. rc=$rc" ; exit 1 ; fi
    cd $BASEDIR
    success "OK"
}   

#--------------------------------------------------
function list_helm_installs() {
    h1 "Listing the installed helm applications"

    helm list
    success "OK"
}

#--------------------------------------------------
locate_this_script
find_kube_namespace
check_env_vars_are_set
# flush_temp_folder
create_temp_folder
# clone_harbor_helm_chart_github_repo
make_sure_harbor_isnt_already_installed
customise_helm_chart
customise_helm_values

install_harbor_using_helm
list_helm_installs 

info "Now type the command 'watch kubectl get pods' to monitor the pods coming up"

