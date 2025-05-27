#! /usr/bin/env bash 

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#
#-----------------------------------------------------------------------------------------                   
#
# Objectives: Check that the built artifacts are all signed.
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
# Main logic.
#-----------------------------------------------------------------------------------------                   

mkdir -p temp

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


function check_maven_repo_for_jar_asc {
    artifact_name=$1

    # For example, the following repo needs checking...
    # https://development.galasa.dev/prerelease/maven-repo/obr/dev/galasa/dev.galasa.wrapping.com.auth0.jwt/

    url="https://development.galasa.dev/${release_type}/maven-repo/obr/dev/galasa/${artifact_name}/"
    curl $url > temp/top_level_maven_contents_${artifact_name}.txt
    rc=$?; 
    if [[ "${rc}" != "0" ]]; then 
      error "Failed to get top-level information from maven repo for artifact ${artifact_name}"
      exit 1
    fi


    # Gives us something like this:
    # <html>
    #  <head>
    #   <title>Index of /prerelease/maven-repo/obr/dev/galasa/dev.galasa.wrapping.com.auth0.jwt</title>
    #  </head>
    #  <body>
    # <h1>Index of /prerelease/maven-repo/obr/dev/galasa/dev.galasa.wrapping.com.auth0.jwt</h1>
    # <pre>      <a href="?C=N;O=D">Name</a>                                     <a href="?C=M;O=A">Last modified</a>      <a href="?C=S;O=A">Size</a>  <hr>      <a href="/prerelease/maven-repo/maven/dev/galasa/">Parent Directory</a>                                              -   
    #       <a href="0.39.0/">0.39.0/</a>                                   2023-06-13 12:58    -   
    #       <a href="maven-metadata.xml">maven-metadata.xml</a>                       2023-06-13 12:58  303   
    #       <a href="maven-metadata.xml.md5">maven-metadata.xml.md5</a>                   2023-06-13 12:58   32   
    #       <a href="maven-metadata.xml.sha1">maven-metadata.xml.sha1</a>                  2023-06-13 12:58   40   
    # <hr></pre>
    # </body></html>
    #
    # ... and we need to pick-out the '0.39.0' version number.

    # Note: We take the 2nd line which has an "<a href" string on... hopefully it won't change...
    artifact_version=$(cat temp/top_level_maven_contents_${artifact_name}.txt | grep "<a href" | head -2 | tail -1 | cut -f2 -d'"' | cut -f1 -d'/')

    info "Version of artifact ${artifact_name} is ${artifact_version}"

    url="https://development.galasa.dev/${release_type}/maven-repo/obr/dev/galasa/${artifact_name}/${artifact_version}/"
    info "Looking at url for a more detailed list of artifacts. url: $url"

    # -L option follows re-directs.
    curl -L $url > temp/detailed_level_maven_contents_${artifact_name}.txt
    rc=$?; 
    if [[ "${rc}" != "0" ]]; then 
      error "Failed to get detailed-level information from maven repo for artifact ${artifact_name}"
      exit 1
    fi

    # That file downloaded should contain the string "${artifact_name}-${artifact_version}.pom.asc"
    info "looking for the .pom.asc in the maven file listing..."
    grep "${artifact_name}-${artifact_version}.pom.asc" temp/detailed_level_maven_contents_${artifact_name}.txt 
    rc=$?
    if [[ "${rc}" != "0" ]]; then 
        error "The .pom.asc file for artifact ${artifact_name} is missing!"
        exit 1
    fi

    success "The .pom.asc file for artifact ${artifact_name} was found."
}

ask_user_for_release_type

declare -a artifact_list=(
    "dev.galasa.platform"\
    "dev.galasa.wrapping.com.auth0.jwt"\
    "dev.galasa.gradle.impl"\
    "galasa-maven-plugin"\
    "dev.galasa.framework"\
    "dev.galasa.ras.couchdb"\
    "dev.galasa.core.manager"\
    "dev.galasa.uber.obr"
)

# Iterate the string array using for loop
for artifact in ${artifact_list[@]}; do
  check_maven_repo_for_jar_asc $artifact
done

success "All checks done and passed."