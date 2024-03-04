#! /usr/bin/env bash 

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#
#-----------------------------------------------------------------------------------------                   
#
# Objectives: Build all the code in github release/prerelease branches.
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


function set_kubernetes_context {
    h1 "Setting the kubernetes context to be cicsk8s, using namespace galasa-build"
    kubectl config set-context cicsk8s --namespace=galasa-build
    rc=$?
    if [[ "${rc}" != "0" ]]; then 
        error "Failed. rc=${rc}"
        exit 1
    fi
}



function build_all_code {

    yaml_file="build_code.yaml"

    rm -f temp/${yaml_file}
    cat << EOF > temp/${yaml_file}

#
# Copyright contributors to the Galasa project 
#
kind: PipelineRun
apiVersion: tekton.dev/v1beta1
metadata:
  generateName: complete-build-
  annotations:
    argocd.argoproj.io/compare-options: IgnoreExtraneous
    argocd.argoproj.io/sync-options: Prune=false
spec:
  params:
  - name: toBranch
    value: ${release_type}
  - name: revision
    value: ${release_type}
  - name: refspec
    value: refs/heads/${release_type}:refs/heads/${release_type}
  - name: imageTag
    value: ${release_type}
  - name: appname
    value: ${release_type}-maven-repos
  - name: jacocoEnabled
    value: "false"
    
    # true if the branch is 'main' or 'release' or 'prerelease'
    # This parameter is used by pom.xmls and build.gradles to complete GPG signing of the artefacts only if true
  - name: isMainOrRelease
    value: "true"
# 
# 
# Start the Complete Build at the Wrapping pipeline
# 
# 
  pipelineRef:
    name: branch-wrapping
  serviceAccountName: galasa-build-bot
# 
# 
# 
  podTemplate:
    volumes:
    - name: gradle-properties
      secret:
        secretName: gradle-properties
    - name: gpg-key
      secret:
        secretName: gpg-key
    - name: mavengpg
      secret:
        secretName: mavengpg
    - name: githubcreds
      secret:
        secretName: github-token
    - name: harborcreds
      secret:
        secretName: harbor-creds-yaml
    - name: mavencreds
      secret:
        secretName: maven-creds
  workspaces:
  - name: git-workspace
    volumeClaimTemplate:
      spec:
        storageClassName: longhorn-temp
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 20Gi

EOF

    output=$(kubectl -n galasa-build create -f temp/${yaml_file})
    # Outputs a line of text like this: 
    # pipelinerun.tekton.dev/complete-build-part1-8cbj8 created
    rc=$?
    if [[ "${rc}" != "0" ]]; then
        error "Failed to start the complete build pipeline. rc=$?"
        exit 1
    fi
    info "kubectl create pipeline run output: $output"


    pipeline_run_name=$(echo $output | grep "created" | cut -f1 -d" " | xargs)


    success "Branch build for Wrapping kicked off - this should trigger the full chain of builds up to and including Isolated (Wrapping > Gradle > Maven > Framework > Extensions > OBR > OBR Generic > CLI > Isolated)."
    bold "Now use the tekton dashboard to monitor it to see that they all work."
    note "If the 'Isolated' build completes OK, then we know that the complete build worked."
}


ask_user_for_release_type
set_kubernetes_context
build_all_code