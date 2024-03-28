#! /usr/bin/env bash 

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#
#-----------------------------------------------------------------------------------------                   
#
# Objectives: Deploys maven artifacts to OSS Sonatype
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

mkdir -p temp

export release_type="release"

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
    galasa_version=$(cat temp/galasa-version.txt | grep '<a * href=\"[0-9]*\.[0-9]*\.[0-9]*\/\"' | head -2 | tail -1 | cut -f2 -d'"' | cut -f1 -d'/')

    success "Galasa version to be tested and released is ${galasa_version}"
    export galasa_version
}

function set_kubernetes_context {
    namespace="galasa-build"
    h1 "Setting the kubernetes context to be cicsk8s, using namespace ${namespace}"
    kubectl config set-context cicsk8s --namespace=${namespace}
    rc=$?
    if [[ "${rc}" != "0" ]]; then 
        error "Failed. rc=${rc}"
        exit 1
    fi
    success "Kubernetes context set to cicsk8s using namespace ${namespace}"
}



function deploy_maven_artifacts {

    h1 "Deploying all Galasa artifacts at version ${galasa_version}"

    branch_name="${release_type}"

    rm -f temp/deploy-maven-galasa.yaml
    cat << EOF > temp/deploy-maven-galasa.yaml

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#

kind: PipelineRun
apiVersion: tekton.dev/v1beta1
metadata:
  generateName: deploy-maven-galasa-
  annotations:
    argocd.argoproj.io/compare-options: IgnoreExtraneous
    argocd.argoproj.io/sync-options: Prune=false
spec:
  params:
  - name: version
    value: "$galasa_version"
  pipelineRef:
    name: deploy-maven-galasa
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

EOF

    output=$(kubectl -n galasa-build create -f temp/deploy-maven-galasa.yaml)
    # Outputs a line of text like this: 
    # pipelinerun.tekton.dev/deploy-maven-galasa-jzcvf created
    rc=$?
    if [[ "${rc}" != "0" ]]; then
        error "Failed to deploy maven artifacts. rc=$?"
        exit 1
    fi
    info "kubectl create pipeline run output: $output"


    pipeline_run_name=$(echo $output | grep "created" | cut -f1 -d" " | xargs)

    MAX_WAIT_ITERATIONS=30
    COUNTER=0
    while [  $COUNTER -lt $MAX_WAIT_ITERATIONS ]; do
        info "Sleeping, waiting for pipeline run ${pipeline_run_name} to succeed.." 
        # Sleep for a second.
        sleep 10
        let COUNTER=COUNTER+1 

        # Find the status of the pipeline run...
        status=$(kubectl get $pipeline_run_name | tail -1 | xargs | cut -f2 -d' ')
        if [[ "${status}" == "True" ]]; then
            info "Pipeline run completed OK."
            break
        fi

        if [[ "${status}" == "False" ]]; then
            error "Pipeline run $pipeline_run_name failed."
            exit 1
            break
        fi
    done
    
    if [ ${COUNTER} -ge $MAX_WAIT_ITERATIONS ]; then 
        error "Timed out waiting for pipeline run ${pipeline_run_name} to complete."
        exit 1
    fi

    success "All maven artifacts have been successfully deployed. Yay!"
}

get_galasa_version_to_be_released
set_kubernetes_context
deploy_maven_artifacts