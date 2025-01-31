#! /usr/bin/env bash 

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#
#-----------------------------------------------------------------------------------------                   
#
# Objectives: To create the resources image.
#
# Environment variable over-rides:
# None.
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


#-----------------------------------------------------------------------------------------                   
# Main logic.
#-----------------------------------------------------------------------------------------   

mkdir -p ${WORKSPACE_DIR}/temp


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


function create_resources_image {

    h1 "Creating the resources image..."

    dist_branch="release"
    version="${galasa_version}"

    github_username=$(gh api user --jq '.login')

    if [[ $? != 0 ]]; then
        error "Failed to get the github username. $?"
        exit 1
    fi

    workflow_dispatch=$( gh workflow run "build resources" --repo ${github_username}/automation --ref main --field distBranch=${dist_branch} --field version=${version})
    if [[ $? != 0 ]]; then
        error "Failed to call the workflow. $?"
        exit 1
    fi

    sleep 3

    run_id=$(gh run list --repo ${github_username}/automation --user ${github_username} --limit 1 --json  databaseId --jq '.[0].databaseId')

    if [[ $? != 0 ]]; then
        error "Failed to get the workflow run_id. $?"
        exit 1
    fi

    echo "Workflow started with Run ID: ${run_id}"
    echo -e "\e]8;;https://github.com/jaydee029/automation/actions/runs/${run_id}\e\\Open Workflow Log\e]8;;\e\\ for more info."

    success "Resources image build pipeline kicked off OK."
}

get_galasa_version_to_be_released

create_resources_image

note "Now wait for the 'resources-*' pipeline to complete."