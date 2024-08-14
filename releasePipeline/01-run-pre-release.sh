#!/bin/bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#
#-----------------------------------------------------------------------------------------                   
#
# Objectives: Run all the pre-release steps 
#
# Environment variable over-rides:
# 
#-----------------------------------------------------------------------------------------     

# Where is this script executing from ?
RELEASE_BASEDIR=$(dirname "$0");pushd $RELEASE_BASEDIR 2>&1 >> /dev/null ;RELEASE_BASEDIR=$(pwd);popd 2>&1 >> /dev/null
export ORIGINAL_DIR=$(pwd)
cd "${RELEASE_BASEDIR}"
CALLED_BY_PRERELEASE="true"
export release_type="prerelease" 

#--------------------------------------------------------------------------
#
# Set Colors
#
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
underline() { printf "${underline}${bold}%s${reset}\n" "$@" ; }
h1()        { printf "\n${underline}${bold}${blue}%s${reset}\n" "$@" ; }
h2()        { printf "\n${underline}${bold}${white}%s${reset}\n" "$@" ; }
debug()     { printf "${white}%s${reset}\n" "$@" ; }
info()      { printf "${white}➜ %s${reset}\n" "$@" ; }
success()   { printf "${green}✔ %s${reset}\n" "$@" ; }
error()     { printf "${red}✖ %s${reset}\n" "$@" ; }
warn()      { printf "${tan}➜ %s${reset}\n" "$@" ; }
bold()      { printf "${bold}%s${reset}\n" "$@" ; }
note()      { printf "\n${underline}${bold}${blue}Note:${reset} ${blue}%s${reset}\n" "$@" ; }


#-----------------------------------------------------------------------------------------                   
# Main Program
#-----------------------------------------------------------------------------------------   
function load_script {
    cd ${RELEASE_BASEDIR}
    script_path="$1"

    source "${script_path}"
}

set -e

load_script $RELEASE_BASEDIR/02-create-argocd-apps.sh
h1 "run 02-create-argocd-apps.sh"
create_maven_repos
create_cli

load_script $RELEASE_BASEDIR/03-repo-branches-delete.sh
h1 "run 03-repo-branches-delete.sh"
set_kubernetes_context
delete_branches

load_script $RELEASE_BASEDIR/04-repo-branches-create.sh
h1 "run 04-repo-branches-create.sh"
set_kubernetes_context
create_branches

load_script $RELEASE_BASEDIR/05-helm-charts.sh
h1 "run 05-helm-charts.sh"
get_galasa_version_to_be_released
clone_helm_repository
get_helm_charts
check_helm_charts_released
delete_pre_release_helm_charts

load_script $RELEASE_BASEDIR/20-build-all-code.sh
h1 "run 20-build-all-code.sh"
ask_user_for_release_type
set_kubernetes_context
build_all_code

# This will need to be removed once the webui is built as part of the main build chain
# (see https://github.com/galasa-dev/projectmanagement/issues/1960)
load_script $RELEASE_BASEDIR/21-build-webui.sh
h1 "run 21-build-webui.sh"
ask_user_for_release_type
set_kubernetes_context
build_webui
