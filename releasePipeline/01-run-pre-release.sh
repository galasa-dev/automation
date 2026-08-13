#!/usr/bin/env bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#
#-----------------------------------------------------------------------------------------
#
# Objectives: Run pre-release steps. Runs all steps when invoked without --step, or a
#             single named step when --step <name> is supplied.
#
# Environment variable over-rides:
#
#-----------------------------------------------------------------------------------------

# Where is this script executing from ?
RELEASE_BASEDIR=$(dirname "$0");pushd $RELEASE_BASEDIR 2>&1 >> /dev/null ;RELEASE_BASEDIR=$(pwd);popd 2>&1 >> /dev/null
export ORIGINAL_DIR=$(pwd)
cd "${RELEASE_BASEDIR}"

#--------------------------------------------------------------------------
#
# Set Colors
#
#--------------------------------------------------------------------------
bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr0)
red=$(tput setaf 1)
green=$(tput setaf 76)
white=$(tput setaf 7)
tan=$(tput setaf 202)
blue=$(tput setaf 25)

#--------------------------------------------------------------------------
#
# Headers and Logging
#
#--------------------------------------------------------------------------
underline() { printf "${underline}${bold}%s${reset}\n" "$@" ; }
h1()        { printf "\n${underline}${bold}${blue}%s${reset}\n" "$@" ; }
h2()        { printf "\n${underline}${bold}${white}%s${reset}\n" "$@" ; }
debug()     { printf "${white}%s${reset}\n" "$@" ; }
info()      { printf "${white}➜ %s${reset}\n" "$@" ; }
success()   { printf "${green}✔ %s${reset}\n" "$@" ; }
error()     { printf "${red}✖ %s${reset}\n" "$@" ; }
warn()      { printf "${tan}➜ %s${reset}\n" "$@" ; }
bold()      { printf "${bold}%s${reset}\n" "$@" ; }
note()      { printf "\n${underline}${bold}${blue}Note:${reset} ${blue}%s${reset}\n" "$@" ; }

#-----------------------------------------------------------------------------------------
# Step functions
#-----------------------------------------------------------------------------------------

function step_create_argocd_apps {
    h1 "run 02-create-argocd-apps.sh"
    $RELEASE_BASEDIR/02-create-argocd-apps.sh --prerelease
}

function step_delete_branches {
    h1 "run 03-repo-branches-delete.sh"
    $RELEASE_BASEDIR/03-repo-branches-delete.sh --prerelease
}

function step_create_branches {
    h1 "run 04-repo-branches-create.sh"
    $RELEASE_BASEDIR/04-repo-branches-create.sh --prerelease
}

function step_helm_charts {
    local start_time=$1
    h1 "run 05-helm-charts.sh"
    $RELEASE_BASEDIR/05-helm-charts.sh --prerelease --start-time "${start_time}"
}

function step_build_mono_repo {
    h1 "run 10-build-galasa-mono-repo.sh"
    $RELEASE_BASEDIR/10-build-galasa-mono-repo.sh --prerelease --wait
}

function step_wait_isolated {
    local start_time=$1
    h1 "Waiting for isolated build to complete"
    $RELEASE_BASEDIR/wait-for-workflow.sh --repo "galasa-dev/isolated" --workflow "build.yaml" --branch "prerelease" --start-time "${start_time}" --name "Isolated build" --sleep 120
}

function step_wait_webui {
    local start_time=$1
    h1 "Waiting for web UI build to complete"
    $RELEASE_BASEDIR/wait-for-workflow.sh --repo "galasa-dev/webui" --workflow "build.yaml" --branch "prerelease" --start-time "${start_time}" --name "Web UI build"
}

function step_check_artifacts_signed {
    h1 "run 20-check-artifacts-signed.sh"
    $RELEASE_BASEDIR/20-check-artifacts-signed.sh --prerelease
}

#-----------------------------------------------------------------------------------------
# Parse arguments
#-----------------------------------------------------------------------------------------
STEP=""
START_TIME=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --step)
            STEP="$2"
            shift 2
            ;;
        --start-time)
            START_TIME="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

#-----------------------------------------------------------------------------------------
# Main Program
#-----------------------------------------------------------------------------------------
set -e

if [[ -z "${STEP}" ]]; then
    h1 "Running all pre-release steps"

    step_create_argocd_apps
    step_delete_branches

    BRANCH_CREATE_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    info "Branch creation time: ${BRANCH_CREATE_TIME}"

    step_create_branches
    step_helm_charts "${BRANCH_CREATE_TIME}"

    BUILD_START_TIME="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    info "Build start time: ${BUILD_START_TIME}"

    step_build_mono_repo
    step_wait_isolated "${BUILD_START_TIME}"
    step_wait_webui "${BUILD_START_TIME}"
    step_check_artifacts_signed

    success "Pre-release automation completed successfully!"
    exit 0
fi

case "${STEP}" in
    create-argocd-apps)
        step_create_argocd_apps
        ;;
    delete-branches)
        step_delete_branches
        ;;
    create-branches)
        step_create_branches
        ;;
    helm-charts)
        if [[ -z "${START_TIME}" ]]; then
            error "--start-time is required for step: helm-charts"
            exit 1
        fi
        step_helm_charts "${START_TIME}"
        ;;
    build-mono-repo)
        step_build_mono_repo
        ;;
    wait-isolated)
        if [[ -z "${START_TIME}" ]]; then
            error "--start-time is required for step: wait-isolated"
            exit 1
        fi
        step_wait_isolated "${START_TIME}"
        ;;
    wait-webui)
        if [[ -z "${START_TIME}" ]]; then
            error "--start-time is required for step: wait-webui"
            exit 1
        fi
        step_wait_webui "${START_TIME}"
        ;;
    check-artifacts-signed)
        step_check_artifacts_signed
        ;;
    *)
        error "Unknown step: '${STEP}'"
        exit 1
        ;;
esac

success "Step '${STEP}' completed successfully!"
