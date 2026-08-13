#!/usr/bin/env bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#
#-----------------------------------------------------------------------------------------
#
# Objectives: Run release steps. Runs all steps when invoked without --step, or a
#             single named step when --step <name> is supplied.
#
# Environment variable over-rides:
#
#-----------------------------------------------------------------------------------------

# Set TERM if not already set
if [ -z "${TERM}" ]; then
    export TERM="xterm-256color"
fi

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
    h1 "Step 1: Set up ArgoCD apps and GitHub branches"
    $RELEASE_BASEDIR/02-create-argocd-apps.sh --release
}

function step_delete_branches {
    h1 "Step 2: Delete old release branches"
    $RELEASE_BASEDIR/03-repo-branches-delete.sh --release
}

function step_create_branches {
    h1 "Step 3: Create new release branches"
    $RELEASE_BASEDIR/04-repo-branches-create.sh --release
}

function step_helm_charts {
    local start_time=$1
    h1 "Step 4: Check Helm charts released"
    $RELEASE_BASEDIR/05-helm-charts.sh --release --start-time "${start_time}"
}

function step_build_mono_repo {
    h1 "Step 5: Build Galasa monorepo"
    $RELEASE_BASEDIR/10-build-galasa-mono-repo.sh --release --wait
}

function step_wait_isolated {
    local start_time=$1
    h1 "Step 6: Wait for Isolated build"
    $RELEASE_BASEDIR/wait-for-workflow.sh --repo "galasa-dev/isolated" --workflow "build.yaml" --branch "release" --start-time "${start_time}" --name "Isolated build" --sleep 120
}

function step_wait_webui {
    local start_time=$1
    h1 "Step 7: Wait for Web UI build"
    $RELEASE_BASEDIR/wait-for-workflow.sh --repo "galasa-dev/webui" --workflow "build.yaml" --branch "release" --start-time "${start_time}" --name "Web UI build"
}

function step_check_artifacts_signed {
    h1 "Step 8: Check artifacts are signed"
    $RELEASE_BASEDIR/20-check-artifacts-signed.sh --release
}

function step_test_mvp_zip {
    h1 "Step 9: Test MVP zip"
    $RELEASE_BASEDIR/test-mvp-zip.sh --release
}

function step_run_isolated_tests {
    h1 "Step 10a: Start Isolated tests workflow"
    $RELEASE_BASEDIR/23-run-isolated-tests.sh --release 2>&1 | tail -n 1
}

function step_run_simbank_ivts {
    h1 "Step 10b: Start Simbank IVTs workflow"
    $RELEASE_BASEDIR/24-run-simbank-ivts.sh --release 2>&1 | tail -n 1
}

function step_run_core_ivts {
    h1 "Step 10c: Start Core IVTs workflow"
    $RELEASE_BASEDIR/25-run-ivts.sh --release 2>&1 | tail -n 1
}

function wait_for_regression_workflow {
    local repo=$1
    local run_id=$2
    local workflow_name=$3

    MAX_WAIT_ITERATIONS=60
    COUNTER=0
    SLEEP_TIME_SECONDS=60

    info "Waiting for ${workflow_name} to complete..."

    while [[ $COUNTER -lt $MAX_WAIT_ITERATIONS ]]; do
        sleep $SLEEP_TIME_SECONDS || true
        ((COUNTER++)) || true

        status=$(gh run view "$run_id" --repo "$repo" --json conclusion --jq '.conclusion' 2>/dev/null)

        if [[ $? -ne 0 ]]; then
            warn "Failed to query workflow status"
            continue
        fi

        if [[ "$status" == "success" ]]; then
            success "${workflow_name} completed successfully"
            return 0
        elif [[ "$status" == "failure" || "$status" == "cancelled" ]]; then
            error "${workflow_name} failed. Check https://github.com/${repo}/actions/runs/${run_id}"
            exit 1
        fi

        # Show progress every 5 minutes
        if [[ $((COUNTER % 5)) -eq 0 ]]; then
            info "${workflow_name} still running... (${COUNTER} minutes elapsed)"
        fi
    done

    error "Timed out waiting for ${workflow_name}"
    exit 1
}

function step_wait_regression_isolated {
    local run_id=$1
    h1 "Step 10d: Wait for Isolated regression tests"
    wait_for_regression_workflow "galasa-dev/isolated" "${run_id}" "Isolated tests"
}

function step_wait_regression_simbank {
    local run_id=$1
    h1 "Step 10e: Wait for Simbank IVTs"
    wait_for_regression_workflow "galasa-dev/simplatform" "${run_id}" "Simbank IVTs"
}

function step_wait_regression_core {
    local run_id=$1
    h1 "Step 10f: Wait for Core IVTs"
    wait_for_regression_workflow "galasa-dev/automation" "${run_id}" "Core IVTs"
}

#-----------------------------------------------------------------------------------------
# Parse arguments
#-----------------------------------------------------------------------------------------
STEP=""
START_TIME=""
RUN_ID=""

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
        --run-id)
            RUN_ID="$2"
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
    h1 "Running all release steps"

    START_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    info "Release process started at: ${START_TIME}"

    step_create_argocd_apps
    step_delete_branches

    BRANCH_CREATE_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    info "Branch creation time: ${BRANCH_CREATE_TIME}"

    step_create_branches
    step_helm_charts "${BRANCH_CREATE_TIME}"
    step_build_mono_repo
    step_wait_isolated "${START_TIME}"
    step_wait_webui "${START_TIME}"
    step_check_artifacts_signed
    step_test_mvp_zip

    h1 "Step 10: Run GitHub Actions regression tests"
    isolated_run_id=$(step_run_isolated_tests)
    simbank_run_id=$(step_run_simbank_ivts)
    core_run_id=$(step_run_core_ivts)
    step_wait_regression_isolated "${isolated_run_id}"
    step_wait_regression_simbank "${simbank_run_id}"
    step_wait_regression_core "${core_run_id}"

    success "Automated release steps completed. Manual steps remain."
    bold ""
    bold "Next manual steps:"
    bold "1. MEND scan (see release.md line 63)"
    bold "2. Run Tekton regression tests (scripts 27-28)"
    bold "3. Run the 'Deploy new Galasa version' workflow"
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
    test-mvp-zip)
        step_test_mvp_zip
        ;;
    run-isolated-tests)
        step_run_isolated_tests
        ;;
    run-simbank-ivts)
        step_run_simbank_ivts
        ;;
    run-core-ivts)
        step_run_core_ivts
        ;;
    wait-regression-isolated)
        if [[ -z "${RUN_ID}" ]]; then
            error "--run-id is required for step: wait-regression-isolated"
            exit 1
        fi
        step_wait_regression_isolated "${RUN_ID}"
        ;;
    wait-regression-simbank)
        if [[ -z "${RUN_ID}" ]]; then
            error "--run-id is required for step: wait-regression-simbank"
            exit 1
        fi
        step_wait_regression_simbank "${RUN_ID}"
        ;;
    wait-regression-core)
        if [[ -z "${RUN_ID}" ]]; then
            error "--run-id is required for step: wait-regression-core"
            exit 1
        fi
        step_wait_regression_core "${RUN_ID}"
        ;;
    *)
        error "Unknown step: '${STEP}'"
        exit 1
        ;;
esac

success "Step '${STEP}' completed successfully!"
