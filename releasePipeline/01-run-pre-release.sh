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
set -e

h1 "run 02-create-argocd-apps.sh"
$RELEASE_BASEDIR/02-create-argocd-apps.sh --prerelease

h1 "run 03-repo-branches-delete.sh"
$RELEASE_BASEDIR/03-repo-branches-delete.sh --prerelease

h1 "run 04-repo-branches-create.sh"
$RELEASE_BASEDIR/04-repo-branches-create.sh --prerelease

h1 "run 05-helm-charts.sh"
$RELEASE_BASEDIR/05-helm-charts.sh --prerelease

h1 "run 10-build-galasa-mono-repo.sh"
$RELEASE_BASEDIR/10-build-galasa-mono-repo.sh --prerelease --wait

h1 "run 20-check-artifacts-signed.sh"
$RELEASE_BASEDIR/20-check-artifacts-signed.sh
