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
h1() { printf "\n${underline}${bold}${blue}%s${reset}\n" "$@";}
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


#-----------------------------------------------------------------------------------------   
function usage {
    info "Syntax: trigger-pipeline.sh [OPTIONS]"
    cat << EOF
Options are:

(from the 'main' build chain)
--gradle
--maven
--framework
--extensions
--managers
--obr
--cli
--eclipse
--wrapping
--obr-generic
--simplatform
--isolated
--webui

Environment variables used:
None
EOF
}

#-----------------------------------------------------------------------------------------   
function check_tkn_installed {
    which tkn > /dev/null
    rc=$?
    if [[ "${rc}" != "0" ]]; then
        error "tkn command is not installed. Install it now using 'brew install tektoncd-cli'"
        exit 1
    fi
}

#--------------------------------------------------------------------------
# 
# Main script logic
#
#--------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------                   
# Process parameters
#-----------------------------------------------------------------------------------------                   
pipeline=""

while [ "$1" != "" ]; do
    case $1 in
        --gradle )              pipeline="gradle"
                                ;;
        --maven )               pipeline="maven"
                                ;;
        --framework )           pipeline="framework"
                                ;;
        --extensions )          pipeline="extensions"
                                ;;
        --managers )            pipeline="managers"
                                ;;
        --obr )                 pipeline="obr"
                                ;;
        --cli )                 pipeline="cli"
                                ;;
        --eclipse )             pipeline="eclipse"
                                ;;
        --wrapping )            pipeline="wrapping"
                                ;;
        --obr-generic )         pipeline="obr-generic"
                                ;;
        --simplatform )         pipeline="simplatform"
                                ;;
        --isolated )            pipeline="isolated"
                                ;;
        --webui )               pipeline="webui"
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     error "Unexpected argument $1"
                                usage
                                exit 1
    esac
    shift
done

if [[ "${pipeline}" == "" ]]; then
    error "Need to use either one of the flags to indicate which pipeline to trigger"
    usage
    exit 1  
fi


check_tkn_installed


tkn pipeline start branch-$pipeline -n galasa-build --prefix-name trigger-$pipeline-main \
--workspace name=git-workspace,volumeClaimTemplateFile=pipelines/templates/git-workspace-template.yaml \
--pod-template pipelines/templates/pod-template.yaml --serviceaccount galasa-build-bot --use-param-defaults

rc=$?
if [[ "${rc}" != "0" ]]; then
    error "tkn command failed to kick off the pipeline. rc=$rc"
    exit 1
fi

success "Pipeline $pipeline kicked off OK."