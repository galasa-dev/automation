#!/bin/bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#

#-----------------------------------------------------------------------------------------                   
#
# Objectives: Sets the version number of this component.
#
# Environment variable over-rides:
# None
# 
#-----------------------------------------------------------------------------------------                   

bootstrap="https://galasa-galasa-prod.cicsk8s.hursley.ibm.com/bootstrap"

version=""

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
function usage {
    h1 "Syntax"
    cat << EOF
set-version.sh [OPTIONS]
Options are:
-v | --version xxx : Mandatory. Set the version number to something explicitly.
    This should be the new development version number.
    For example '--version 0.29.0'
EOF
}

function SetVersionIsolated {
    h1 "Set version for isolated.full.zip to $version"

    cmd="galasactl properties set \
    --namespace galasaecosystem \
    --name isolated.full.zip \
    --value https://development.galasa.dev/main/maven-repo/isolated/dev/galasa/galasa-isolated/$version/galasa-isolated-$version.zip \
    --bootstrap $bootstrap"

    $cmd
    rc=$?

    if [[ "${rc}" != "0" ]]; then 
        error "Failed to update version to $version for isolated.full.zip"
        exit 1
    fi

    success "OK"
}

function SetVersionMVP {
    h1 "Set version for solated.mvp.zip to $version"

    cmd="galasactl properties set \
    --namespace galasaecosystem \
    --name isolated.mvp.zip \
    --value https://development.galasa.dev/main/maven-repo/mvp/dev/galasa/galasa-isolated-mvp/$version/galasa-isolated-mvp-$version.zip \
    --bootstrap $bootstrap"

    $cmd
    rc=$?

    if [[ "${rc}" != "0" ]]; then 
        error "Failed to update version to $version for solated.mvp.zip"
        exit 1
    fi

    success "OK"
}

function SetVersionRuntime {
    h1 "Set version for runtime.version to $version"

    cmd="galasactl properties set \
    --namespace galasaecosystem \
    --name runtime.version  \
    --value $version \
    --bootstrap $bootstrap"

    $cmd
    rc=$?

    if [[ "${rc}" != "0" ]]; then 
        error "Failed to update version to $version for isolated.full.zip"
        exit 1
    fi

    success "OK"
}
#-----------------------------------------------------------------------------------------                   
# Process parameters
#-----------------------------------------------------------------------------------------                   

while [ "$1" != "" ]; do
    case $1 in
        -v | --version )        shift
                                export version=$1
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

if [[ -z $version ]]; then 
    error "Missing mandatory '--version' argument."
    usage
    exit 1
fi

SetVersionIsolated
SetVersionMVP
SetVersionRuntime