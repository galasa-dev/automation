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
    info "Syntax: build-locally.sh [OPTIONS]"
    cat << EOF
Options are:
-c | --clean : Do a clean build. One of the --clean or --delta flags are mandatory.
-d | --delta : Do a delta build. One of the --clean or --delta flags are mandatory.

Environment variables used:
None
EOF
}

#--------------------------------------------------------------------------
# 
# Main script logic
#
#--------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------                   
# Process parameters
#-----------------------------------------------------------------------------------------                   
build_type=""

while [ "$1" != "" ]; do
    case $1 in
        -c | --clean )          build_type="clean"
                                ;;
        -d | --delta )          build_type="delta"
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

if [[ "${build_type}" == "" ]]; then
    error "Need to use either the --clean or --delta parameter."
    usage
    exit 1  
fi


#--------------------------------------------------------------------------
# Clean up if we need to.
#--------------------------------------------------------------------------
if [[ "${build_type}" == "clean" ]]; then
    h2 "Cleaning the binaries out..."
    cd ${BASEDIR}/build-images/github-webhook-receiver
    make clean
    rc=$? ; if [[ "${rc}" != "0" ]]; then error "Failed to build and run unit tests. rc=${rc}" ; exit 1 ; fi
    success "Binaries cleaned up - OK"
fi

#--------------------------------------------------------------------------
# Setup go packages
#--------------------------------------------------------------------------
h2 "Getting dependent Go packages..."
cd ${BASEDIR}/build-images/github-webhook-receiver
make setup
rc=$? ; if [[ "${rc}" != "0" ]]; then error "Failed to get golang dependencies. rc=${rc}" ; exit 1 ; fi
success "New binaries built - OK"

#--------------------------------------------------------------------------
# Build and invoke unit tests
#--------------------------------------------------------------------------
h2 "Building new binaries..."
cd ${BASEDIR}/build-images/github-webhook-receiver
make delta-build
rc=$? ; if [[ "${rc}" != "0" ]]; then error "Failed to build binary executable programs. rc=${rc}" ; exit 1 ; fi
success "New binaries built - OK"

#--------------------------------------------------------------------------
# Build the documentation
# generated_docs_folder=${BASEDIR}/github-webhook-receiver/docs/generated
# h2 "Generating documentation"
# info "Documentation will be placed in ${generated_docs_folder}"
# mkdir -p ${generated_docs_folder}

# # Figure out which type of machine this script is currently running on.
# unameOut="$(uname -s)"
# case "${unameOut}" in
#     Linux*)     machine=linux;;
#     Darwin*)    machine=darwin;;
#     *)          error "Unknown machine type ${unameOut}"
#                 exit 1
# esac
# architecture="$(uname -m)"

# # Call the documentation generator, which builds .md files
# info "Using program ${BASEDIR}/bin/gendocs-github-webhook-receiver-${machine}-${architecture} to generate the documentation..."
# ${BASEDIR}/bin/gendocs-galasactl-${machine}-${architecture} ${generated_docs_folder}
# rc=$? ; if [[ "${rc}" != "0" ]]; then error "Failed to generate documentation. rc=${rc}" ; exit 1 ; fi

# # The files have a line "###### Auto generated by cobra at 17/12/2022"
# # As we are (currently) checking-in these .md files, we don't want them to show as 
# # changed in git (which compares the content, not timestamps).
# # So lets remove these lines from all the .md files.
# info "Removing lines with date/time in, to limit delta changes in git..."
# mkdir -p ${BASEDIR}/build
# temp_file="${BASEDIR}/build/temp.md"
# for FILE in ${generated_docs_folder}/*; do 
#     mv -f ${FILE} ${temp_file}
#     cat ${temp_file} | grep -v "###### Auto generated by" > ${FILE}
#     rm ${temp_file}
#     success "Processed file ${FILE}"
# done
# success "Documentation generated - OK"

#--------------------------------------------------------------------------
h2 "Use the results.."
info "Binary executable programs are found in the 'bin' folder."
ls ${BASEDIR}/build-images/github-webhook-receiver/bin | grep -v "gendocs"