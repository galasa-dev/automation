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
underline() { printf "${underline}${bold}%s${reset}\n" "$@" ; }
h1() { printf "\n${underline}${bold}${blue}%s${reset}\n" "$@" ; }
h2() { printf "\n${underline}${bold}${white}%s${reset}\n" "$@" ; }
debug() { printf "${white}%s${reset}\n" "$@" ;}
info() { printf "${white}➜ %s${reset}\n" "$@" ;}
success() { printf "${green}✔ %s${reset}\n" "$@" ;}
error() { printf "${red}✖ %s${reset}\n" "$@";}
warn() { printf "${tan}➜ %s${reset}\n" "$@";}
bold() { printf "${bold}%s${reset}\n" "$@";}
note() { printf "\n${underline}${bold}${blue}Note:${reset} ${blue}%s${reset}\n" "$@";}

#-----------------------------------------------------------------------------------------                   
# Functions
#-----------------------------------------------------------------------------------------                   
function usage {
    info "Syntax: run-locally.sh [OPTIONS]"
    cat << EOF
Options are:
None

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
        -h | --help )           usage
                                exit
                                ;;
        * )                     error "Unexpected argument $1"
                                usage
                                exit 1
    esac
    shift
done

h2 "Working out the machine architecture to use."
architecture=$(uname -m)
case $architecture in
    arm64 )
        ;;
    amd64 )
        ;;
    x86-64 )
        architecture="amd64" 
        ;;
    *)
        error "Architecture $architecture is not supported by this script"
        exit 1
esac
success "Architecture is ${architecture}"

h2 "Working out which operating system we are running on"
os=$(uname -o)
case $os in
    Darwin )
        os="darwin"
        ;;
    Linux | linux )
        os="linux"
        ;;
    *)
        error "Operating system $os is not supported by this script"
        exit 1
esac
success "Operating system is $os"

executable="ghmonitor-${os}-${architecture}"

rm -fr ${BASEDIR}/temp
mkdir ${BASEDIR}/temp
cd ${BASEDIR}/temp

cat << EOF > ${BASEDIR}/temp/ghmonitor-trigger-map.yaml
events: 
  pull_request:
      eventListener: "something.namespace.svc.cluster.local"
  pull_request_review:
      eventListener: "somethingElse.namespace.svc.cluster.local"
EOF

h2 "Calling the tool $executable"

# if [[ -z GITHUB_PUBLIC_PERSONAL_ACCESS_TOKEN ]]; then
#     GITHUB_PUBLIC_PERSONAL_ACCESS_TOKEN=input
# fi

export GITHUBTOKEN=${GITHUB_PUBLIC_PERSONAL_ACCESS_TOKEN}

cmd="${BASEDIR}/bin/${executable} \
--hook 386623630 \
--org galasa-dev \
--bookmark ${BASEDIR}/temp/ghmonitor-bookmark.txt \
--trigger-map ${BASEDIR}/temp/ghmonitor-trigger-map.yaml "
info "Running command $cmd"
$cmd
