#!/bin/bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#

#-----------------------------------------------------------------------------------------                   
#
# Objectives: Update the version of CPS properties
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

function usage {
    h1 "Syntax"
    cat << EOF
set-version.sh [OPTIONS]
Options are:
-v | --version xxx : Mandatory. Set the version number to something explicitly. 
    Updates the version numbers for properties in the cps-properties.yaml file.
    For example '--version 0.41.0'
-h | --help : Displays this syntax information.
EOF
}

#-----------------------------------------------------------------------------------------                   
# Process parameters
#-----------------------------------------------------------------------------------------                   
galasa_version=""

while [ "$1" != "" ]; do
    case $1 in
        -v | --version )        shift
                                galasa_version="$1"
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

if [[ -z $galasa_version ]]; then 
    error "Missing mandatory '--version' argument."
    usage
    exit 1
fi

#-----------------------------------------------------------------------------------------
# Functions
#-----------------------------------------------------------------------------------------

function update_property_version {
    file_path=$1
    property_name=$2
    value_regex=$3
    new_value=$4

    h1 "Bumping up the version of '${property_name}' in ${file_path}"

    mkdir -p ${BASEDIR}/temp
    temp_file="${BASEDIR}/temp/cps-properties.yaml"

    cat ${file_path} | sed -E "s/${value_regex}/${new_value}/1" > ${temp_file}
    rc=$?; if [[ "${rc}" != "0" ]]; then error "Failed to bump version of '${property_name}' in ${file_path} file."; exit 1; fi

    cp ${temp_file} ${file_path}
    if ! grep -q -E "${new_value}" ${file_path}; then error "Failed to replace all relevant occurrences of the old version value."; exit 1; fi

    success "'${property_name}' version bumped successfully"
}

# bumping version for the value of property test.stream.ivts.location
function upgrade_test_stream_ivts_location_version {
    property_name="test.stream.ivts.location"
    service_main_properties_file="${WORKSPACE_DIR}/infrastructure/galasa-kube1/galasa-service1/galasa-service-main-resources.yaml"
    value_regex="https:\\/\\/development[.]galasa[.]dev\\/main\\/maven-repo\\/ivts\\/dev\\/galasa\\/dev[.]galasa[.]ivts[.]obr\\/[0-9.]+\\/dev[.]galasa[.]ivts[.]obr-[0-9.]+-testcatalog[.]json"
    new_value="https:\\/\\/development.galasa.dev\\/main\\/maven-repo\\/ivts\\/dev\\/galasa\\/dev.galasa.ivts.obr\\/${galasa_version}\\/dev.galasa.ivts.obr-${galasa_version}-testcatalog.json"

    update_property_version "${service_main_properties_file}" "${property_name}" "${value_regex}" "${new_value}"
}

# bumping version for the value of property test.stream.ivts.obr
function upgrade_test_stream_ivts_obr_version {
    property_name="test.stream.ivts.obr"
    service_main_properties_file="${WORKSPACE_DIR}/infrastructure/galasa-kube1/galasa-service1/galasa-service-main-resources.yaml"
    value_regex="mvn:dev.galasa\\/dev[.]galasa[.]ivts[.]obr\\/[0-9.]+\\/obr"
    new_value="mvn:dev.galasa\\/dev.galasa.ivts.obr\\/${galasa_version}\\/obr"

    update_property_version "${service_main_properties_file}" "${property_name}" "${value_regex}" "${new_value}"
}

#bumping version for the secure-ivts GalasaStream resource
function upgrade_secure_ivts_stream_version {
    h1 "Bumping up the version in the secure-ivts GalasaStream resource"
    
    service_main_resources_file="${WORKSPACE_DIR}/infrastructure/galasa-kube1/galasa-service1/galasa-service-main-resources.yaml"
    
    # Update the version field in the obrs section
    version_regex="version: [0-9.]+"
    version_new_value="version: ${galasa_version}"
    
    # Update the testCatalog URL
    testcatalog_regex="url: https:\\/\\/development[.]galasa[.]dev\\/main\\/maven-repo\\/ivts-auth\\/dev\\/galasa\\/dev[.]galasa[.]ivts[.]obr\\/[0-9.]+\\/dev[.]galasa[.]ivts[.]obr-[0-9.]+-testcatalog[.]json"
    testcatalog_new_value="url: https:\\/\\/development.galasa.dev\\/main\\/maven-repo\\/ivts-auth\\/dev\\/galasa\\/dev.galasa.ivts.obr\\/${galasa_version}\\/dev.galasa.ivts.obr-${galasa_version}-testcatalog.json"
    
    mkdir -p ${BASEDIR}/temp
    temp_file="${BASEDIR}/temp/galasa-service-main-resources.yaml"
    
    # Apply both replacements
    cat ${service_main_resources_file} | sed -E "s/${version_regex}/${version_new_value}/1" | sed -E "s/${testcatalog_regex}/${testcatalog_new_value}/1" > ${temp_file}
    rc=$?; if [[ "${rc}" != "0" ]]; then error "Failed to bump version in secure-ivts GalasaStream resource."; exit 1; fi
    
    cp ${temp_file} ${service_main_resources_file}
    if ! grep -q -E "${version_new_value}" ${service_main_resources_file}; then error "Failed to replace version field in secure-ivts GalasaStream resource."; exit 1; fi
    if ! grep -q -E "dev.galasa.ivts.obr\\/${galasa_version}\\/dev.galasa.ivts.obr-${galasa_version}-testcatalog.json" ${service_main_resources_file}; then error "Failed to replace testCatalog URL in secure-ivts GalasaStream resource."; exit 1; fi
    
    success "secure-ivts GalasaStream version bumped successfully"
}

#-----------------------------------------------------------------------------------------
# Main logic.
#-----------------------------------------------------------------------------------------

upgrade_test_stream_ivts_location_version
upgrade_test_stream_ivts_obr_version
upgrade_secure_ivts_stream_version
