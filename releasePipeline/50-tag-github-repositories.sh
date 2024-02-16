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


function set_kubernetes_context {
    h1 "Setting the kubernetes context to be cicsk8s, using namespace galasa-build"
    kubectl config set-context cicsk8s --namespace=galasa-build
    rc=$?
    if [[ "${rc}" != "0" ]]; then 
        error "Failed. rc=${rc}"
        exit 1
    fi
    
}

function tag_galasa_github_repositories {

    h1 "Tagging the github repositories..."

    cd ${WORKSPACE_DIR}/temp
    yaml_file=${WORKSPACE_DIR}/temp/tag-galasa-repositories.yaml
    cat << EOF > $yaml_file
#
# Copyright contributors to the Galasa project 
#
kind: PipelineRun
apiVersion: tekton.dev/v1beta1
metadata:
  generateName: tag-galasa-
  annotations:
    argocd.argoproj.io/compare-options: IgnoreExtraneous
    argocd.argoproj.io/sync-options: Prune=false
#
#
#
spec:
#
#
#
  pipelineRef:
    name: branch-tag-galasa
  
  serviceAccountName: galasa-build-bot

  podTemplate:
    volumes:
    - name: githubcreds
      secret:
        secretName: github-token
    - name: harborcreds
      secret:
        secretName: harbor-creds-yaml
    - name: mavencreds
      secret:
        secretName: maven-creds

  params:
  - name: distBranch
    value: "release"
#
#  Tag must be in the format v0.0.0
#
  - name: tag
    value: "v${galasa_version}"
EOF

    cmd="kubectl -n galasa-build create -f $yaml_file"
    info "Command is $cmd"
    $cmd
    rc=$?
    if [[ "${rc}" != "0" ]]; then
        error "Failed to create the resources image. rc=$rc"
        exit 1
    fi

    success "Resources image build pipeline kicked off OK."
}

set_kubernetes_context
get_galasa_version_to_be_released

tag_galasa_github_repositories

note "Now wait for the 'tag-galasa-*' pipeline to complete."
note "Expect it to take about a minute."
note "Check that it passed"