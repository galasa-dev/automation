#! /usr/bin/env bash 

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#
#-----------------------------------------------------------------------------------------                   
#
# Objectives: To release the new version of the Helm charts.
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
    info "Syntax: 05-helm-charts.sh [OPTIONS]"
    cat << EOF
Options are:
--prerelease : Checks the Galasa helm charts can be released for the pre-release process.
--release : Checks the Galasa helm charts have been released for the release process.
--start-time <timestamp> : ISO 8601 timestamp to use for filtering workflow runs (optional, defaults to current time)
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


function get_galasa_version_to_be_released {
    h1 "Working out the version of Galasa that is being released."

    url="https://development.galasa.dev/main/maven-repo/obr/dev/galasa/dev.galasa.uber.obr/"
    curl $url > temp/galasa-version.txt -s
    rc=$?; 
    if [[ "${rc}" != "0" ]]; then 
      error "Failed to get galasa version"
      exit 1
    fi

    # Note: We take the 2nd line which has an "<a href" string on... hopefully it won't change...
    galasa_version=$(cat temp/galasa-version.txt | grep "<a href" | head -2 | tail -1 | cut -f2 -d'"' | cut -f1 -d'/')

    success "Galasa version being released is ${galasa_version}"
    export galasa_version
}


function clone_helm_repository {

    h1 "Cloning the '${release_type}' branch of the 'helm' repository into the 'temp' directory..."

    cd ${WORKSPACE_DIR}/temp
    git clone --branch ${release_type} https://github.com/galasa-dev/helm.git
    
    success "'${release_type}' branch of the 'helm' repository cloned."

}


function get_helm_charts {

    h1 "Getting the names of the various Helm charts for different components..."

    charts_directory=${WORKSPACE_DIR}/temp/helm/charts
    charts=()

    for dir in "$charts_directory"/*/; do

        version_line=$(cat ${dir}Chart.yaml | grep "version:")
        version=$(echo "$version_line" | sed 's/version: "//' | sed 's/"$//')

        if [[ "$version" == "$galasa_version" ]]; then
            charts+=("$(basename "$dir")")
        fi
    done

    info "Helm charts that have been updated in this release version:"
    for chart in "${charts[@]}"; do
        info "$chart"
    done

}


function check_helm_charts_released {

    cd ${WORKSPACE_DIR}

    h1 "Checking the Helm charts were released..."

    info "Waiting for Helm chart release workflow to start and complete..."

    # Use the provided start time or default to current time
    if [[ -z "${start_time}" ]]; then
        start_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        info "No start time provided, using current time: ${start_time}"
    fi
    
    info "Looking for workflow runs created after: ${start_time}"

    workflow_found="false"
    workflow_finished="false"
    retries=0
    max=100
    run_id=""

    while [[ "${workflow_finished}" == "false" ]]; do

        # Get recent workflow runs for the release branch
        url="https://api.github.com/repos/galasa-dev/helm/actions/workflows/release.yaml/runs?branch=${release_type}&per_page=5"
        curl -s "$url" > temp/helm_workflow_runs.json

        # Find the most recent run created after our branch creation time
        if [[ "${workflow_found}" == "false" ]]; then
            # Look for a workflow run that started after we created the branch
            run_id=$(cat temp/helm_workflow_runs.json | jq -r --arg start_time "$start_time" '.workflow_runs[] | select(.created_at > $start_time) | .id' | head -1)
            
            if [[ -n "$run_id" ]]; then
                workflow_found="true"
                info "Found Helm release workflow run: ${run_id}"
                info "View at: https://github.com/galasa-dev/helm/actions/runs/${run_id}"
            else
                info "Waiting for Helm release workflow to start... (attempt $((retries+1))/${max})"
            fi
        fi

        # If we found the workflow, check its status
        if [[ "${workflow_found}" == "true" ]]; then
            status=$(cat temp/helm_workflow_runs.json | jq -r --arg run_id "$run_id" '.workflow_runs[] | select(.id == ($run_id | tonumber)) | .status')
            conclusion=$(cat temp/helm_workflow_runs.json | jq -r --arg run_id "$run_id" '.workflow_runs[] | select(.id == ($run_id | tonumber)) | .conclusion')
            
            if [[ "$status" == "completed" ]]; then
                if [[ "$conclusion" == "success" ]]; then
                    success "Helm release workflow completed successfully."
                    workflow_finished="true"
                else
                    error "Helm release workflow failed with conclusion: ${conclusion}"
                    error "Check https://github.com/galasa-dev/helm/actions/runs/${run_id}"
                    exit 1
                fi
            else
                info "Helm release workflow status: ${status}"
            fi
        fi

        if [[ "${workflow_finished}" == "false" ]]; then
            sleep 5
            ((retries++))
            if (( $retries > $max )); then
                error "Timed out waiting for Helm release workflow."
                if [[ -n "$run_id" ]]; then
                    error "Check https://github.com/galasa-dev/helm/actions/runs/${run_id}"
                else
                    error "Check https://github.com/galasa-dev/helm/actions"
                fi
                exit 1
            fi
        fi
    done

    for chart in "${charts[@]}"; do

        release_tag=$chart-$galasa_version

        info "Checking if the "$release_tag" chart was released"

        url="https://api.github.com/repos/galasa-dev/helm/releases"
        response=$(curl -s "$url")

        if [[ "$response" == *"\"tag_name\": \"$release_tag\","* ]]; then
            success "Release $release_tag exists in the repository."
        else
            error "Release $release_tag does not exist in the repository."
            exit 1
        fi

        info "Checking if the "$release_tag" tag was created"

        url="https://api.github.com/repos/galasa-dev/helm/tags"
        curl $url > temp/helm-tags.txt -s

        target_line=$(cat temp/helm-tags.txt | grep "\"name\": \"${release_tag}\"")

        if [[ "$target_line" != "" ]]; then
            success "Tag $release_tag exists in the repository."
        else
            error "Tag $release_tag does not exist in the repository."
            exit 1
        fi

    done

    success "All Helm charts released OK. Yay!"

}

function delete_pre_release_helm_charts {

    # remove release tag for pre-release process
    for chart in "${charts[@]}"; do

        release_tag=$chart-$galasa_version

        # Delete pre-release github release
        delete_command="gh release delete $release_tag --repo galasa-dev/helm --cleanup-tag --yes"
        info "Delete release for $release_tag using the command $delete_command."
        $delete_command
        rc=$?
        if [[ "${rc}" != "0" ]]; then
            error "Failed to delete release with tag $release_tag. rc=${rc}. You must manually delete the release and the associated tag at https://github.com/galasa-dev/helm/releases"
        else
            success "Deleted release for $release_tag OK."
        fi
    done
}

#-----------------------------------------------------------------------------------------
# Process parameters
#-----------------------------------------------------------------------------------------
release_type=""
start_time=""
while [ "$1" != "" ]; do
    case $1 in
        --prerelease )          release_type="prerelease"
                                ;;
        --release )             release_type="release"
                                ;;
        --start-time )          shift
                                start_time="$1"
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
rm -rf ${WORKSPACE_DIR}/temp
mkdir -p ${WORKSPACE_DIR}/temp

if [[ -z "${release_type}" ]]; then
    ask_user_for_release_type
fi

get_galasa_version_to_be_released
clone_helm_repository
get_helm_charts
check_helm_charts_released

if [[ "$release_type" == "prerelease" ]]; then
    delete_pre_release_helm_charts
    bold "This is a pre-release. We don't actually want to keep the Release/Tags that were just created. Make sure to delete them!"
fi

