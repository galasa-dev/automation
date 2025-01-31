#! /usr/bin/env bash 

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#
#-----------------------------------------------------------------------------------------                   
#
# Objectives: To tag all the repositories in github.
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


function tag_galasa_github_repositories {

    h1 "Tagging the github repositories..."

    dist_branch="release"
    tag="v${galasa_version}"

    github_username=$(gh api user --jq '.login')

    if [[ $? != 0 ]]; then
        error "Failed to get the github username. $?"
        exit 1
    fi

    workflow_dispatch=$( gh workflow run branch-tag-galasa --repo ${github_username}/automation --ref main --field distBranch=${dist_branch} --field tag=${tag})

    if [[ $? != 0 ]]; then
        error "Failed to call the workflow. $?"
        exit 1
    fi

    run_id=$(gh run list --repo ${github_username}/automation --user ${github_username} --limit 1 --json  databaseId --jq '.[0].databaseId')

    if [[ $? != 0 ]]; then
        error "Failed to get the workflow run_id. $?"
        exit 1
    fi

    echo "Workflow started with Run ID: ${run_id}"

    MAX_WAIT_ITERATIONS=30
    COUNTER=0

    while [[ $COUNTER -lt $MAX_WAIT_ITERATIONS ]]; do
        echo "Waiting for workflow ${run_id} to complete..."
        sleep 10
        ((COUNTER++))
        
        echo -e "\e]8;;https://github.com/jaydee029/automation/actions/runs/${run_id}\e\\Open Workflow Log\e]8;;\e\\ for more info."

        status=$(gh run view "$run_id" --repo ${github_username}/automation --json conclusion --jq '.conclusion')

        if [[ "$status" == "success" ]]; then
            echo "Workflow completed successfully."
            break
        elif [[ "$status" == "failure" || "$status" == "cancelled" ]]; then
            echo "Workflow failed. Check the workflow run for more details."
            exit 1
        fi
    done

    if [[ $COUNTER -ge $MAX_WAIT_ITERATIONS ]]; then
        echo "⏳ Timed out waiting for workflow ${run_id} to complete."
        exit 1
    fi

    rc=$?
    if [[ "${rc}" != "0" ]]; then
        error "Failed to tag the branches. rc=$?"
        exit 1
    fi

    success "Tagged the github repositories with tag ${tag}"
}

get_galasa_version_to_be_released

tag_galasa_github_repositories
