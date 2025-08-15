#! /usr/bin/env bash 

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#
#-----------------------------------------------------------------------------------------                   
#
# Objectives: Deletes all the release-type branches in each github repo
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

#-----------------------------------------------------------------------------------------                   
# Functions
#-----------------------------------------------------------------------------------------                   

function usage {
    info "Syntax: 03-repo-branches-delete.sh [OPTIONS]"
    cat << EOF
Options are:
--prerelease : Deletes any pre-release branches in the galasa-dev repositories.
--release : Deletes any release branches in the galasa-dev repositories.
EOF
}

function ask_user_for_release_type {
    PS3="Select the type of release process please: "
    select lng in release pre-release
    do
        case $lng in
            "release")
                export release_type="release"
                break
                ;;
            "pre-release")
                export release_type="prerelease"
                break
                ;;
            *)
            echo "Unrecognised input.";;
        esac
    done
    echo "Chosen type of release process: ${release_type}"
}

function delete_branches {

    h1 "Deleting all branches in github called ${release_type}"

    workflow_dispatch=$( gh workflow run "Branch Delete" --repo galasa-dev/automation --ref main --field distBranch=${release_type})

    if [[ $? != 0 ]]; then
        error "Failed to call the workflow. $?"
        exit 1
    fi

    sleep 5

    run_id=$(gh run list --repo galasa-dev/automation --workflow "Branch Delete" --limit 1 --json  databaseId --jq '.[0].databaseId')

    if [[ $? != 0 ]]; then
        error "Failed to get the workflow run_id. $?"
        exit 1
    fi

    echo "Workflow started with Run ID: ${run_id}"
    
    echo "Open Workflow Log at https://github.com/galasa-dev/automation/actions/runs/${run_id} for more info."


    MAX_WAIT_ITERATIONS=30
    COUNTER=0

    while [[ $COUNTER -lt $MAX_WAIT_ITERATIONS ]]; do
        echo "Waiting for workflow ${run_id} to complete..."
        sleep 10
        ((COUNTER++))
        
        status=$(gh run view "$run_id" --repo galasa-dev/automation --json conclusion --jq '.conclusion')

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
        error "Failed to delete the branches. rc=$?"
        exit 1
    fi

    success "All branches called ${release_type} are now deleted. Yay!"
}

#-----------------------------------------------------------------------------------------
# Process parameters
#-----------------------------------------------------------------------------------------
release_type=""
while [ "$1" != "" ]; do
    case $1 in
        --prerelease )          release_type="prerelease"
                                ;;
        --release )             release_type="release"
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

# ------------------------------------------------------------------------
# Main logic
# ------------------------------------------------------------------------
if [[ -z "${release_type}" ]]; then
    ask_user_for_release_type
fi

delete_branches
