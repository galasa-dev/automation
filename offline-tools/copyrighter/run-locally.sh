#!/usr/bin/env bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#

# Objectives: 
# Give the tooling a spin to basically make sure it still works.

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

#-------------------------------------------------------------------------
# Clean
#-------------------------------------------------------------------------
rm -fr temp
mkdir -p temp

#-------------------------------------------------------------------------
# Set version to use based on the machine architecture...
#-------------------------------------------------------------------------
function set_tool_version {
    raw_os=$(uname -s) # eg: "Darwin"
    os=""

    case $raw_os in
        Darwin*) 
            os="darwin" 
            ;;
        Linux*)
            os="linux"
            ;;
        *) 
            error "Failed to recognise which operating system is in use. $raw_os"
            exit 1
    esac

    architecture=$(uname -m)

    export GALASACOPYRIGHTER="${BASEDIR}/bin/galasacopyrighter-${os}-${architecture}"
}

function allow_tool_to_execute {
    h2 "Setting execute permissions"
    chmod +x ${GALASACOPYRIGHTER}
    success "OK"
}

function run_tool {
    h2 "Running the galasacopyrighter tool..."
    cmd="$GALASACOPYRIGHTER $*"
    info "Calling $cmd"
    $cmd
    rc=$?
    if [[ "${rc}" != "0" ]]; then
        error "The tool $GALASACOPYRIGHTER failed. rc=$rc"
        exit 1
    fi
    success "OK"    
}

set_tool_version
allow_tool_to_execute
run_tool $*
