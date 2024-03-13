#! /usr/bin/env bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#
#-----------------------------------------------------------------------------------------
# Objective: Run regression tests from a given branch in a given repo.
#-----------------------------------------------------------------------------------------
BASEDIR=$(dirname "$0");pushd $BASEDIR 2>&1 >> /dev/null;BASEDIR=$(pwd);popd 2>&1 >> /dev/null
cd "${BASEDIR}/.."
WORKSPACE_DIR=$(pwd)
cd "${BASEDIR}"

#-----------------------------------------------------------------------------------------
# Set Colors
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
# Headers and Logging
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

#-----------------------------------------------------------------------------------------
# Functions
#-----------------------------------------------------------------------------------------
function usage {
    info "usage: run-regression-tests.sh [OPTIONS]"
    cat << EOF
Options are:
-r <repo_name> | --repo <repo_name> : The name of the GitHub repository that the branch to build from can be found within.
-b <branch> | --branch <branch> : The name of the branch that will be built from.
-bs <URI> | --bootstrap <URI> : The URI of the bootstrap properties for galasactl to use (mandatory).
-h | --help : Display usage information.
EOF
}

function verifyTool {
  which "$1" 2>&1 > /dev/null
  rc=$?
  if [[ "${rc}" != "0" ]]; then
      info "The $1 tool is not available. Install it and try again."
      exit 1
  fi

}

#-----------------------------------------------------------------------------------------
# Process parameters
#-----------------------------------------------------------------------------------------
targetRepository="wrapping"
targetBranch="main"
bootstrap=""

while [ "$1" != "" ]; do
    case $1 in
        -r | --repo )           shift
                                targetRepository="$1"
                                ;;
        -b | --branch )         shift
                                targetBranch="$1"
                                ;;
        -bs | --bootstrap )     shift
                                bootstrap="$1"
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

if [[ "${bootstrap}" == "" ]]; then
    error "Need to specify --bootstrap <URI>."
    usage
    exit 1
fi

#-----------------------------------------------------------------------------------------
# Main logic
#-----------------------------------------------------------------------------------------
verifyTool "argocd"
verifyTool "tkn"
verifyTool "go"

if [[ ! -e "../cli" ]]; then
    error "../cli is not present. Clone the CLI repository from https://github.com/galasa-dev/cli"
    exit 1
fi

# Create a new Argo CD app if a branch other than main is specified, otherwise just run regression tests from main
appName="${targetBranch}-maven-repos"
if [[ "${targetBranch}" != "main" ]]; then
  h1 "Creating Argo CD app ${appName}"
  repositories=(
      'wrapping'
      'maven'
      'gradle'
      'framework'
      'extensions'
      'managers'
      'obr'
  )

  index=-1
  for i in "${!repositories[@]}"; do
    if [[ "${targetRepository}" == "${repositories[$i]}" ]]; then
      index=$i
      break
    fi
  done

  if [[ ${index} -eq -1 ]]; then
    error "Repository '${targetRepository}' not found."
    exit 1
  fi

  h2 "Logging into Argo CD"
  argocd login argocd.galasa.dev --sso --grpc-web

  h2 "Creating app"
  argocd app create "${appName}" \
                    --project default \
                    --sync-policy auto \
                    --sync-option Prune=true \
                    --repo https://github.com/galasa-dev/automation \
                    --revision HEAD \
                    --path infrastructure/galasa-plan-b-lon02/galasa-development/branch-maven-repository \
                    --dest-server https://kubernetes.default.svc \
                    --dest-namespace galasa-development \
                    --grpc-web
  rc=$? ; if [[ "${rc}" != "0" ]]; then error "Failed to create ${appName}." ; exit 1 ; fi

  h2 "Configuring helm parameters"
  for repo in "${repositories[@]:${index}}"; do
      argocd app set "${appName}" \
        --helm-set "${repo}.branch=${targetBranch}" \
        --helm-set "${repo}.imageTag=${targetBranch}" \
        --helm-set "${repo}.deploy=true" \
        --grpc-web
  done
  success "${appName} app created."

  pipeline="branch-${targetRepository}"
  h1 "Starting ${pipeline} build pipeline"
  tkn pipeline start "${pipeline}" \
      --param fromBranch="main" \
      --param toBranch="${targetBranch}" \
      --param imageTag="${targetBranch}" \
      --param refspec="refs/heads/${targetBranch}:refs/heads/${targetBranch}" \
      --param appname="${appName}" \
      --workspace name=git-workspace,volumeClaimTemplateFile=pipelines/templates/git-workspace-template.yaml \
      --pod-template pipelines/templates/pod-template.yaml \
      --serviceaccount galasa-build-bot \
      -n galasa-build
  rc=$? ; if [[ "${rc}" != "0" ]]; then error "Failed to start ${pipeline} pipeline." ; exit 1 ; fi

  info "Waiting for builds to complete..."
  while [[
    "$(curl "https://development.galasa.dev/${targetBranch}/maven-repo/obr/" \
    --silent \
    --output /dev/null \
    --write-out "%{response_code}")" != "200"
  ]]; do
    sleep 5
  done
  success "Builds complete."
fi

h1 "Creating regression test portfolio"
cd "${WORKSPACE_DIR}/cli"
galasactlPath="cmd/galasactl/main.go"

go run ${galasactlPath} runs prepare \
    --portfolio test.yaml \
    --bootstrap "${bootstrap}" \
    --stream inttests \
    --package local
rc=$? ; if [[ "${rc}" != "0" ]]; then error "Failed to create regression test portfolio." ; exit 1 ; fi
success "Portfolio created."

h1 "Starting regression tests"
go run ${galasactlPath} runs submit \
    --bootstrap "${bootstrap}" \
    --portfolio test.yaml \
    --reportyaml tests.yaml \
    --reportjson tests.json \
    --reportjunit junit.xml \
    --override galasaecosystem.runtime.repository="https://development.galasa.dev/${targetBranch}/maven-repo/obr/" \
    --throttle 6 \
    --poll 10 \
    --progress 1 \
    --trace

cd ${BASEDIR}
success "Regression tests complete."

if [[ "${targetBranch}" != "main" ]]; then
  h1 "Deleting ${appName} Argo CD app"
  argocd app delete "${appName}" -y --grpc-web
  rc=$? ; if [[ "${rc}" != "0" ]]; then error "Failed to delete ${appName}." ; exit 1 ; fi
  success "${appName} app deleted successfully."
fi