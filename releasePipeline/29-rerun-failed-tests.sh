#! /usr/bin/env bash 

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#
#-----------------------------------------------------------------------------------------                   
#
# Objectives: Build all the code in github release/prerelease branches.
#
# Environment variable over-rides:
# 
#-----------------------------------------------------------------------------------------                   

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

function calculate_galasactl_executable {
    h2 "Calculate the name of the galasactl executable for this machine/os"

    raw_os=$(uname -s) # eg: "Darwin"
    os=""
    case $raw_os in
        Darwin*) 
            os="darwin" 
            ;;
        Windows*)
            os="windows"
            ;;
        Linux*)
            os="linux"
            ;;
        *) 
            error "Failed to recognise which operating system is in use. $raw_os"
            exit 1
    esac

    architecture=$(uname -m)

    export galasactl_full_name="galasactl-${os}-${architecture}"
    info "galasactl binary is ${galasactl_full_name}"
    success "OK"
}

function download_galasactl {
    h1 "Downloading galasactl..."
    if [ -d "${BASEDIR}/temp" ] ; then
        mkdir ${BASEDIR}/temp
    fi
    cd ${BASEDIR}/temp

    url="https://development.galasa.dev/main/binary/cli/${galasactl_full_name}"
    curl $url  --output galasactl

    rc=$?

    if [[ "${rc}" != "0" ]]; then
        error "Failed to download galasactl from ${url}. rc=$?"
        exit 1
    fi

    success "Downloaded galasactl."
}

function get_failed_tests {

    bootstrap="https://prod1-galasa-dev.cicsk8s.hursley.ibm.com/api/bootstrap"

    cd ${BASEDIR}/temp
    mkdir -p home
    export GALASA_HOME=${BASEDIR}/temp/home

    pipeline_run_name=$(tkn pipelinerun list | grep "regression-test" | grep "Failed" | cut -f1 -d' ')
    
    regression_test_output_file=$(tkn pipelinerun logs -n galasa-build -a regression-test-jdlc8 | grep "\*\*\*" | sed "s/.*\*\*\*//g" > regression_test_output.txt)



    cmd="${BASEDIR}/temp/galasactl runs get \
    --result Failed,EnvFail \
    --format raw \
    --bootstrap ${bootstrap} "

    output_file="failed-tests-output.txt"
    $cmd | tee $output_file

   
}

calculate_galasactl_executable
download_galasactl
get_failed_tests