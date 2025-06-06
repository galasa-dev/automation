#!/usr/bin/env bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#


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

#--------------------------------------------------------------------------
# 
# Main script logic
#
#--------------------------------------------------------------------------


#-----------------------------------------------------------------------------------------                   
# Functions
#-----------------------------------------------------------------------------------------   

#Make sure to already have your GitHub details set as environment variables; GITHUB_USERNAME, GITHUB_TOKEN
             
function login_to_ghcr(){
    h2 "Logging into GHCR..."

    if [[ -z "${GITHUB_USERNAME}" ]]; then
        error "Please set your GitHub Username as an environment variable"
        exit 1
    fi

    if [[ -z "${GITHUB_TOKEN}" ]]; then
        error "Please set your GitHub personal access token with write:packages and read:packages scope as an environment variable"
        exit 1
    fi

    echo "${GITHUB_TOKEN}" | docker login ghcr.io -u "${GITHUB_USERNAME}" --password-stdin

    rc=$?
    if [[ "${rc}" != "0" ]]; then 
        error "Failed to login to GHCR"
        exit 1
    fi

    success "Logged in to GHCR successfully"
}

function build_and_tag_docker_image(){
    h2 "Building docker image with a tag..."

    make all

    rc=$?
    if [[ "${rc}" != "0" ]]; then 
        error "Failed to build and tag the docker image"
        exit 1
    fi

    success "Image built and tagged successfully"
}

function push_image(){
    h2 "Pushing docker image..."

    docker push ghcr.io/galasa-dev/ghmonitor:main

    rc=$?
    if [[ "${rc}" != "0" ]]; then 
        error "Failed to push the docker image"
        exit 1
    fi

    success "Image pushed successfully"
}

login_to_harbour
build_and_tag_docker_image
push_image