#!/bin/bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#
# Where is this script executing from ?
BASEDIR=$(dirname "$0");pushd $BASEDIR 2>&1 >> /dev/null ;BASEDIR=$(pwd);popd 2>&1 >> /dev/null
# echo "Running from directory ${BASEDIR}"
export ORIGINAL_DIR=$(pwd)
# cd "${BASEDIR}"

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

function get_galasa_version_to_be_released {
    h1 "Working out the version of Galasa to test and release."

    mkdir -p temp

    url="https://development.galasa.dev/main/maven-repo/obr/dev/galasa/dev.galasa.uber.obr/"
    curl $url > temp/galasa-version.txt -s
    rc=$?; 
    if [[ "${rc}" != "0" ]]; then 
      error "Failed to get galasa version"
      exit 1
    fi

    # Note: We take the 2nd line which has an "<a href" string on... hopefully it won't change...
    galasa_version=$(cat temp/galasa-version.txt | grep "<a href" | head -2 | tail -1 | cut -f2 -d'"' | cut -f1 -d'/')

    success "Galasa version to be tested and released is ${galasa_version}"
    export galasa_version
}

function run_command {
    cmd=$*
    h2 "Running command: $cmd..."
    $cmd
    rc=$?
    if [[ "${rc}" != "0" ]]; then 
        error "Command failed. rc=$rc. Command is $cmd"
        exit 1
    fi
    success "OK"
}

#-----------------------------------------------------------------------------------------                   
# Main logic.
#-----------------------------------------------------------------------------------------   


get_galasa_version_to_be_released

set -e

FROM=release

TO=$galasa_version

info "Updating the IBM container registry images from verison $FROM to version $TO"

run_command ibmcloud cr login



run_command docker pull ghcr.io/galasa-dev/restapidoc-site:$FROM
run_command docker pull ghcr.io/galasa-dev/webui:$FROM





run_command docker tag ghcr.io/galasa-dev/restapidoc-site:$FROM \
           icr.io/galasadev/galasa-restapidoc-amd64:$TO

run_command docker tag ghcr.io/galasa-dev/webui:$FROM \
           icr.io/galasadev/galasa-ui:$TO

run_command docker tag ghcr.io/galasa-dev/restapidoc-site:$FROM \
           icr.io/galasadev/galasa-restapidoc-amd64:latest

run_command docker tag ghcr.io/galasa-dev/webui:$FROM \
           icr.io/galasadev/galasa-ui:latest

# Pull and retag the galasa-boot-embedded images
# linux/amd64
run_command docker pull --platform linux/amd64 ghcr.io/galasa-dev/galasa-boot-embedded:$FROM

run_command docker tag ghcr.io/galasa-dev/galasa-boot-embedded:$FROM \
           icr.io/galasadev/galasa-boot-embedded-amd64:$TO

run_command docker tag ghcr.io/galasa-dev/galasa-boot-embedded:$FROM \
           icr.io/galasadev/galasa-boot-embedded-amd64:latest

# linux/arm64
run_command docker pull --platform linux/arm64 ghcr.io/galasa-dev/galasa-boot-embedded:$FROM

run_command docker tag ghcr.io/galasa-dev/galasa-boot-embedded:$FROM \
           icr.io/galasadev/galasa-boot-embedded-arm64:$TO

run_command docker tag ghcr.io/galasa-dev/galasa-boot-embedded:$FROM \
           icr.io/galasadev/galasa-boot-embedded-arm64:latest


run_command docker push icr.io/galasadev/galasa-restapidoc-amd64:$TO
run_command docker push icr.io/galasadev/galasa-boot-embedded-amd64:$TO
run_command docker push icr.io/galasadev/galasa-boot-embedded-arm64:$TO
run_command docker push icr.io/galasadev/galasa-ui:$TO



run_command docker push icr.io/galasadev/galasa-restapidoc-amd64:latest
run_command docker push icr.io/galasadev/galasa-boot-embedded-amd64:latest
run_command docker push icr.io/galasadev/galasa-boot-embedded-arm64:latest
run_command docker push icr.io/galasadev/galasa-ui:latest

# And now for the CLI images...
run_command docker pull ghcr.io/galasa-dev/galasactl-x86_64:$FROM
run_command docker tag ghcr.io/galasa-dev/galasactl-x86_64:$FROM \
           icr.io/galasadev/galasa-cli-amd64:$TO
run_command docker tag ghcr.io/galasa-dev/galasactl-x86_64:$FROM \
           icr.io/galasadev/galasa-cli-amd64:latest
run_command docker push icr.io/galasadev/galasa-cli-amd64:$TO
run_command docker push icr.io/galasadev/galasa-cli-amd64:latest

success "Completed. Updated the IBM container registry images from verison $FROM to version $TO"