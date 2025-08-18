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
    git clone --branch ${release_type} git@github.com:galasa-dev/helm.git
    
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

    info "First, checking that the GitHub Actions workflow to release them, is no longer active..."

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

        # get the release using the tag name and pull out the release url to delete
        release_json_details="temp/$release_tag.txt"
        release_by_tag_url="https://api.github.com/repos/galasa-dev/helm/releases/tags/$release_tag"
        curl $release_by_tag_url > $release_json_details -s
        release_url=$(grep -Ei ' *"url" *: *"(https:\/\/api\.github\.com\/repos\/galasa-dev\/helm\/releases\/[0-9]*)"' $release_json_details | cut -d \" -f 4)

        # Delete pre-release github release
        response_code=$(curl -X DELETE $release_url -w "${response_code}")
        if [[ "${response_code}" != "204" ]]; then 
            error "Unable to delete release for $release_tag using the api url '$release_url'. Expected status code '204' and got '$response_code'."
            exit 1
        fi
        success "Delete release for $release_tag using the api url '$release_url'."
        # Delete pre-release tag
        tag_url="https://api.github.com/repos/galasa-dev/helm/tags/$release_tag"
        response_code= $(curl -X DELETE $url -w "%{response_code}")
        if [[ "${response_code}" != "204" ]]; then 
            error "Unable to delete tag $release_tag using the api url '$tag_url'. Expected status code '204' and got '$response_code'."
            exit 1
        fi
        success "Delete release for $release_tag using the api url '$tag_url'."

    done
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

