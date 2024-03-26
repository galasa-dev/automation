#!/bin/bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#

#-----------------------------------------------------------------------------------------                   
#
# Objectives: Update the version of cps properties
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

function get_galasa_version_to_be_released {
    h1 "Working out the version of Galasa to test and release."

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

function ask_user_for_versions {
    h1 "Please enter the old and new versions of this release..."
    
    read -p "Please enter the old version number: " old_version
    read -p "Please enter the version number: " new_version

    echo "You are doing a release for version ${new_version}, to replace the old version ${old_version}"
}


function change_ver_of_property_value {
    cd ${WORKSPACE_DIR}/infrastructure/cicsk8s/galasa-prod/galasa-prod
    
    file="cps-properties.yaml"

    #TO DO: CHANGE so version numbers in example '-0.32.0-' can be replaced
    #also consider how some values which are '/0.32.0/' should not be changed if not required
    
    #regex pattern to make sure that only version numbers 
    #with a non-whitespace character in front are replaced
    delimited_old_version="\\/${old_version}\\/"
    delimited_new_version="\\/${new_version}\\/"
    
    # echo $delimited_old_version


    sed -i '' "s/"${delimited_old_version}"/"${delimited_new_version}"/g" $file;

    if grep $delimited_old_version $file; then
        error "Failed to replace all occurrences of ${old_version}."
        exit 1
        break
    fi
    
    success "Successfully replaced occurrences of the old version, ${old_version}, with ${new_version}"
}

ask_user_for_versions
change_ver_of_property_value