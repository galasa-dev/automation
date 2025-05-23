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

# bumping version for the value of property test.stream.ivts.location
function upgrade_test_stream_ivts_location_version {
    property_name="test.stream.inttests.location"
    h1 "Bumping up the version of '${property_name}'"
    mkdir -p ${BASEDIR}/temp

    file="${WORKSPACE_DIR}/infrastructure/cicsk8s/galasa-dev/cps-properties.yaml"
    temp_file="${BASEDIR}/temp/cps-properties.yaml"

    value_regex="https:\\/\\/development[.]galasa[.]dev\\/main\\/maven-repo\\/ivts\\/dev\\/galasa\\/dev[.]galasa[.]ivts[.]obr\\/[0-9.]+\\/dev[.]galasa[.]ivts[.]obr-[0-9.]+-testcatalog[.]json"
    new_value="https:\\/\\/development.galasa.dev\\/main\\/maven-repo\\/ivts\\/dev\\/galasa\\/dev.galasa.ivts.obr\\/${galasa_version}\\/dev.galasa.ivts.obr-${galasa_version}-testcatalog.json"
    
    cat ${file} | sed -E "s/${value_regex}/${new_value}/1" > ${temp_file}
    rc=$?; if [[ "${rc}" != "0" ]]; then error "Failed to bump version of '${property_name}' in $file file."; exit 1; fi

    cp ${temp_file} ${file}
    if ! grep -q -E "${new_value}" $file; then error "Failed to replace all relevant occurrences of the old version value."; exit 1; fi

    success "'${property_name}' version bumped successfully"
}

# bumping version for the value of property test.stream.ivts.obr
function upgrade_test_stream_ivts_obr_version {
    property_name="test.stream.inttests.location"
    h1 "Bumping up the version of '${property_name}'"
    mkdir -p ${BASEDIR}/temp

    file="${WORKSPACE_DIR}/infrastructure/cicsk8s/galasa-dev/cps-properties.yaml"
    temp_file="${BASEDIR}/temp/cps-properties.yaml"

    value_regex="mvn:dev.galasa\\/dev[.]galasa[.]ivts[.]obr\\/[0-9.]+\\/obr"
    new_value="mvn:dev.galasa\\/dev.galasa.ivts.obr\\/${galasa_version}\\/obr"
    
    cat ${file} | sed -E "s/${value_regex}/${new_value}/1" > ${temp_file}
    rc=$?; if [[ "${rc}" != "0" ]]; then error "Failed to bump version of '${property_name}' in $file file."; exit 1; fi

    cp ${temp_file} ${file}
    if ! grep -q -E "${new_value}" $file; then error "Failed to replace all relevant occurrences of the old version value."; exit 1; fi

    success "'${property_name}' version bumped successfully"
}

#bumping version for the value of property test.stream.inttests.location
function upgrade_test_stream_inttests_location_version {
    property_name="test.stream.inttests.location"
    h1 "Bumping up the version of '${property_name}'"
    mkdir -p ${BASEDIR}/temp

    file="${WORKSPACE_DIR}/infrastructure/cicsk8s/galasa-dev/cps-properties.yaml"
    temp_file="${BASEDIR}/temp/cps-properties.yaml"

    value_regex="https:\\/\\/development[.]galasa[.]dev\\/main\\/maven-repo\\/inttests\\/dev\\/galasa\\/dev[.]galasa[.]inttests[.]obr\\/[0-9.]+\\/dev[.]galasa[.]inttests[.]obr-[0-9.]+-testcatalog[.]json"
    new_value="https:\\/\\/development.galasa.dev\\/main\\/maven-repo\\/inttests\\/dev\\/galasa\\/dev.galasa.inttests.obr\\/${galasa_version}\\/dev.galasa.inttests.obr-${galasa_version}-testcatalog.json"
    
    cat ${file} | sed -E "s/${value_regex}/${new_value}/1" > ${temp_file}
    rc=$?; if [[ "${rc}" != "0" ]]; then error "Failed to bump version of '${property_name}' in $file file."; exit 1; fi

    cp ${temp_file} ${file}
    if ! grep -q -E "${new_value}" $file; then error "Failed to replace all relevant occurrences of the old version value."; exit 1; fi

    success "'${property_name}' version bumped successfully"
}

#bumping version for the value of property test.stream.inttests.obr
function upgrade_test_stream_inttests_obr_version {
    property_name="test.stream.inttests.obr"
    h1 "Bumping up the version of '${property_name}'"
    mkdir -p ${BASEDIR}/temp

    file="${WORKSPACE_DIR}/infrastructure/cicsk8s/galasa-dev/cps-properties.yaml"
    temp_file="${BASEDIR}/temp/cps-properties.yaml"

    value_regex="mvn:dev.galasa\\/dev[.]galasa[.]inttests[.]obr\\/[0-9.]+\\/obr"
    new_value="mvn:dev.galasa\\/dev.galasa.inttests.obr\\/${galasa_version}\\/obr"

    cat ${file} | sed -E "s/${value_regex}/${new_value}/1" > ${temp_file}
    rc=$?; if [[ "${rc}" != "0" ]]; then error "Failed to bump version of '${property_name}' in $file file."; exit 1; fi

    cp ${temp_file} ${file}
    if ! grep -q -E "${new_value}" $file; then error "Failed to replace all relevant occurrences of the old version value."; exit 1; fi
    
    success "'${property_name}' version bumped successfully"
}

#bumping version for the value of property isolated.full.zip
function upgrade_isolated_full_zip_version {
    property_name="isolated.full.zip"
    h1 "Bumping up the version of '${property_name}'"
    mkdir -p ${BASEDIR}/temp

    file="${WORKSPACE_DIR}/infrastructure/cicsk8s/galasa-dev/cps-properties.yaml"
    temp_file="${BASEDIR}/temp/cps-properties.yaml"

    value_regex="https:\\/\\/development[.]galasa[.]dev\\/main\\/maven-repo\\/isolated\\/dev\\/galasa\\/galasa-isolated\\/[0-9.]+\\/galasa-isolated-[0-9.]+.zip"
    new_value="https:\\/\\/development.galasa.dev\\/main\\/maven-repo\\/isolated\\/dev\\/galasa\\/galasa-isolated\\/${galasa_version}\\/galasa-isolated-${galasa_version}.zip"

    cat ${file} | sed -E "s/${value_regex}/${new_value}/1" > ${temp_file}
    rc=$?; if [[ "${rc}" != "0" ]]; then error "Failed to bump version of '${property_name}' in $file file."; exit 1; fi

    cp ${temp_file} ${file}
    if ! grep -q -E "${new_value}" $file; then error "Failed to replace all relevant occurrences of the old version value."; exit 1; fi
    
    success "'${property_name}' version bumped successfully"
}

#bumping version for the value of property isolated.mvp.zip
function upgrade_isolated_mvp_zip_version {
    property_name="isolated.mvp.zip"
    h1 "Bumping up the version of '${property_name}'"
    mkdir -p ${BASEDIR}/temp

    file="${WORKSPACE_DIR}/infrastructure/cicsk8s/galasa-dev/cps-properties.yaml"
    temp_file="${BASEDIR}/temp/cps-properties.yaml"

    value_regex="https:\\/\\/development[.]galasa[.]dev\\/main\\/maven-repo\\/mvp\\/dev\\/galasa\\/galasa-isolated-mvp\\/[0-9.]+\\/galasa-isolated-mvp-[0-9.]+[.]zip"
    new_value="https:\\/\\/development.galasa.dev\\/main\\/maven-repo\\/mvp\\/dev\\/galasa\\/galasa-isolated-mvp\\/${galasa_version}\\/galasa-isolated-mvp-${galasa_version}.zip"

    cat ${file} | sed -E "s/${value_regex}/${new_value}/1" > ${temp_file}
    rc=$?; if [[ "${rc}" != "0" ]]; then error "Failed to bump version of '${property_name}' in $file file."; exit 1; fi

    cp ${temp_file} ${file}
    if ! grep -q -E "${new_value}" $file; then error "Failed to replace all relevant occurrences of the old version value."; exit 1; fi
    
    success "'${property_name}' version bumped successfully"
}

#bumping version for the value of property runtime.version
function upgrade_galasa_versions {
    runtime_version_prop="runtime.version"
    galasaboot_version_prop="galasaboot.version"
    simbanktests_version_prop="simbanktests.version"
    simplatform_version_prop="simplatform.version"

    h1 "Bumping up the versions for properties that point to the Galasa boot version"
    
    #create a temp file
    temp_file="${BASEDIR}/temp/cps-properties.yaml"
    >$temp_file

    #count variavle to find the 'value: X.XX.X' line
    count=0

    cd ${WORKSPACE_DIR}/infrastructure/cicsk8s/galasa-dev
    source_file="cps-properties.yaml"

    info "Updating file $source_file"
    # Note: There are several matches for value: X.XX.X so we need to find the correct one...
    rm -f $temp_file
    found_property_name="false"
    #[ -n "$line" ] prevents the last line from being deleted if it's not a new line
    while IFS= read -r line || [ -n "$line" ]; do 
        outputLine="$line"
        if [[ "$found_property_name" == "false" ]]; then
            if [[ "$line" =~ \s*${runtime_version_prop}\s* ]] || \
               [[ "$line" =~ \s*${galasaboot_version_prop}\s* ]] || \
               [[ "$line" =~ \s*${simbanktests_version_prop}\s* ]] || \
               [[ "$line" =~ \s*${simplatform_version_prop}\s* ]]; then
                found_property_name="true"
                ((count++))
            fi
        else
            # the line containing the value of the property will always be 
            # the 2nd line after we find the line containing the property name
            if ((count == 2)); then
                info "Before: $line"
                outputLine=$(echo "$line" | sed -E "s/[0-9.]+/${galasa_version}/1")
                info "After: $outputLine"
                found_property_name="false"
                count=0
            else
                #increment count if we've not yet reached the second line
                ((count++))
            fi
        fi
        echo "$outputLine" >> $temp_file
    done < $source_file

    #copy newly-updated temp file into source file with
    cat $temp_file > $source_file

    success "'${property_name}' version bumped successfully"
}

#-----------------------------------------------------------------------------------------
# Main logic.
#-----------------------------------------------------------------------------------------

upgrade_test_stream_ivts_location_version
upgrade_test_stream_ivts_obr_version
upgrade_test_stream_inttests_location_version
upgrade_test_stream_inttests_obr_version
upgrade_isolated_full_zip_version
upgrade_isolated_mvp_zip_version
upgrade_galasa_versions