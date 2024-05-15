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
BASEDIR=$(dirname "$0");pushd $BASEDIR 2>&1 >> /dev/null ;BASEDIR=$(pwd);popd 2>&1 >> /dev/null
export ORIGINAL_DIR=$(pwd)
cd "${BASEDIR}"
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
# Functions
#-----------------------------------------------------------------------------------------   
set -e

h1 "run 02-create-argocd-apps.sh"
source $BASEDIR/02-create-argocd-apps.sh
create-maven-repos
create-cli

h1 "run 03-repo-branches-delete.sh"
source $BASEDIR/03-repo-branches-delete.sh
set_kubernetes_context
delete_branches

h1 "run 04-repo-branches-create.sh"
source $BASEDIR/04-repo-branches-create.sh
set_kubernetes_context
create_branches

h1 "run 05-helm-charts.sh"
source $BASEDIR/05-helm-charts.sh
get_galasa_version_to_be_released
clone_helm_repository
get_helm_charts
check_helm_charts_released
delete_pre_release_helm_charts

h1 "run 20-build-all-code.sh"
source $BASEDIR/20-build-all-code.sh
ask_user_for_release_type
set_kubernetes_context
build_all_code

h1 "run 21-build-webui.sh"
source $BASEDIR/21-build-webui.sh
ask_user_for_release_type
set_kubernetes_context
build_webui