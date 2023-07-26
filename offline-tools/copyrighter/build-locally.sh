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
underline() { printf "${underline}${bold}%s${reset}\n" "$@"
}
h1() { printf "\n${underline}${bold}${blue}%s${reset}\n" "$@"
}
h2() { printf "\n${underline}${bold}${white}%s${reset}\n" "$@"
}
debug() { printf "${white}%s${reset}\n" "$@"
}
info() { printf "${white}➜ %s${reset}\n" "$@"
}
success() { printf "${green}✔ %s${reset}\n" "$@"
}
error() { printf "${red}✖ %s${reset}\n" "$@"
}
warn() { printf "${tan}➜ %s${reset}\n" "$@"
}
bold() { printf "${bold}%s${reset}\n" "$@"
}
note() { printf "\n${underline}${bold}${blue}Note:${reset} ${blue}%s${reset}\n" "$@"
}

#-----------------------------------------------------------------------------------------                   
# Functions
#-----------------------------------------------------------------------------------------                   
function usage {
    info "Syntax: build-locally.sh"
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
        -h | --help )           usage
                                exit
                                ;;
        * )                     error "Unexpected argument $1"
                                usage
                                exit 1
    esac
    shift
done


#--------------------------------------------------------------------------
h1 "Building the copyrighter tool"
#--------------------------------------------------------------------------



#--------------------------------------------------------------------------
#
# Build the executables
#
#--------------------------------------------------------------------------
function build_executables {
    if [[ "${build_type}" == "clean" ]]; then
        h2 "Cleaning the binaries out..."
        make clean
        rc=$? ; if [[ "${rc}" != "0" ]]; then error "Failed to build binary executable galasacopyrighter programs. rc=${rc}" ; exit 1 ; fi
        success "Binaries cleaned up - OK"
    fi

    h2 "Building new binaries..."
    set -o pipefail # Fail everything if anything in the pipeline fails. Else we are just checking the 'tee' return code.
    mkdir -p ${BASEDIR}/build
    make all | tee ${BASEDIR}/build/compile-log.txt
    rc=$? ; if [[ "${rc}" != "0" ]]; then error "Failed to build binary executable galasacopyrighter programs. rc=${rc}. See log at ${BASEDIR}/build/compile-log.txt" ; exit 1 ; fi
    success "New binaries built - OK"
}


# The steps to build the CLI
build_executables

success "OK"
