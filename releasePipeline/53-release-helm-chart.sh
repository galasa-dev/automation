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
    h1 "Working out the version of Galasa to release."

    url="https://development.galasa.dev/main/maven-repo/obr/dev/galasa/dev.galasa.uber.obr/"
    curl $url > temp/galasa-version.txt -s
    rc=$?; 
    if [[ "${rc}" != "0" ]]; then 
      error "Failed to get galasa version"
      exit 1
    fi

    # Note: We take the 2nd line which has an "<a href" string on... hopefully it won't change...
    galasa_version=$(cat temp/galasa-version.txt | grep "<a href" | head -2 | tail -1 | cut -f2 -d'"' | cut -f1 -d'/')

    success "Galasa version to be released is ${galasa_version}"
    export galasa_version
}

function clone_helm_repository {

    h1 "Cloning the 'release' branch of the 'helm' repository into the 'temp' directory..."

    cd ${WORKSPACE_DIR}/temp
    git clone --branch release git@github.com:galasa-dev/helm.git
    
    success "'release' branch of the 'helm' repository cloned."

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

function release_helm_charts {

    cd ${WORKSPACE_DIR}

    h1 "Releasing the Helm charts by pushing the 'release' branch to 'released' which will trigger the GitHub Actions workflow..."

    # Push the contents of the branch 'release' to 'released'
    git push origin release:released

    info "Check that a GitHub Actions workflow has been kicked off..."

    workflow_started="false"
    retries=0
    max=100
    target_line=""

    while [[ "${workflow_started}" == "false" ]]; do

        url=https://api.github.com/repos/galasa-dev/helm/actions/runs?status=in_progress
        curl $url > temp/workflows_in_progress.txt -s

        target_line=$(cat temp/workflows_in_progress.txt | grep "\"total_count\": 1")

        if [[ "$target_line" != "" ]]; then
            success "Target line is found - the workflow is now running."
            workflow_started="true"
        fi    
        sleep 5
        ((retries++))
        if (( $retries > $max )); then 
            error "Too many retries."
            exit 1
        fi
    done

    success "GitHub Actions workflow for releasing the Helm charts has started."

}

function check_helm_charts_released {

    cd ${WORKSPACE_DIR}

    h1 "Checking the Helm charts were released..."

    info "First, waiting for the GitHub Actions workflow to finish..."

    workflow_finished="false"
    retries=0
    max=100
    target_line=""

    while [[ "${workflow_finished}" == "false" ]]; do

        url=https://api.github.com/repos/galasa-dev/helm/actions/runs?status=in_progress
        curl $url > temp/workflows_in_progress.txt -s

        target_line=$(cat temp/workflows_in_progress.txt | grep "\"total_count\": 0")

        if [[ "$target_line" != "" ]]; then
            success "Target line is found - the workflow is now finished."
            workflow_finished="true"
        fi    
        sleep 5
        ((retries++))
        if (( $retries > $max )); then 
            error "Too many retries."
            exit 1
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
    done

    success "All Helm charts released OK."

}

get_galasa_version_to_be_released

clone_helm_repository
get_helm_charts

release_helm_charts
check_helm_charts_released
