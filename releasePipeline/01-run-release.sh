#!/usr/bin/env bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#
#-----------------------------------------------------------------------------------------
#
# Objectives: Run all the release steps
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
# Functions
#-----------------------------------------------------------------------------------------

function wait_for_workflow_completion {
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

function run_github_regression_tests {
    h2 "Starting GitHub Actions regression tests in parallel"
    
    # Start all three workflows in parallel using existing scripts
    info "Starting Isolated tests workflow..."
    isolated_run_id=$($RELEASE_BASEDIR/23-run-isolated-tests.sh --release 2>&1 | tail -n 1)
    if [[ $? != 0 || -z "$isolated_run_id" ]]; then
        error "Failed to start Isolated tests workflow"
        exit 1
    fi
    
    info "Starting Simbank IVTs workflow..."
    simbank_run_id=$($RELEASE_BASEDIR/24-run-simbank-ivts.sh --release 2>&1 | tail -n 1)
    if [[ $? != 0 || -z "$simbank_run_id" ]]; then
        error "Failed to start Simbank IVTs workflow"
        exit 1
    fi
    
    info "Starting Core IVTs workflow..."
    core_run_id=$($RELEASE_BASEDIR/25-run-ivts.sh --release 2>&1 | tail -n 1)
    if [[ $? != 0 || -z "$core_run_id" ]]; then
        error "Failed to start Core IVTs workflow"
        exit 1
    fi
    
    success "Workflow runs started:"
    bold "  - Isolated tests: https://github.com/galasa-dev/isolated/actions/runs/${isolated_run_id}"
    bold "  - Simbank IVTs: https://github.com/galasa-dev/simplatform/actions/runs/${simbank_run_id}"
    bold "  - Core IVTs: https://github.com/galasa-dev/automation/actions/runs/${core_run_id}"
    
    # Wait for all workflows to complete
    wait_for_workflow_completion "galasa-dev/isolated" "$isolated_run_id" "Isolated tests"
    wait_for_workflow_completion "galasa-dev/simplatform" "$simbank_run_id" "Simbank IVTs"
    wait_for_workflow_completion "galasa-dev/automation" "$core_run_id" "Core IVTs"
    
    success "All GitHub Actions regression tests completed successfully"
}

#-----------------------------------------------------------------------------------------
# Main logic
#-----------------------------------------------------------------------------------------

set -e

# Capture start time for workflow tracking
START_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
info "Release process started at: ${START_TIME}"

h1 "Step 1: Set up ArgoCD apps and GitHub branches"
$RELEASE_BASEDIR/02-create-argocd-apps.sh --release

h1 "Step 2: Delete old release branches"
$RELEASE_BASEDIR/03-repo-branches-delete.sh --release

h1 "Step 3: Create new release branches"
$RELEASE_BASEDIR/04-repo-branches-create.sh --release

h1 "Step 4: Check Helm charts released"
$RELEASE_BASEDIR/05-helm-charts.sh --release

h1 "Step 5: Build Galasa mono repo"
$RELEASE_BASEDIR/10-build-galasa-mono-repo.sh --release --wait

h1 "Step 6: Wait for Isolated build"
$RELEASE_BASEDIR/wait-for-workflow.sh --repo "galasa-dev/isolated" --workflow "build.yaml" --branch "release" --start-time "$START_TIME" --name "Isolated build" --sleep 120

h1 "Step 7: Wait for Web UI build"
$RELEASE_BASEDIR/wait-for-workflow.sh --repo "galasa-dev/webui" --workflow "build.yaml" --branch "release" --start-time "$START_TIME" --name "Web UI build"

h1 "Step 8: Check artifacts are signed"
$RELEASE_BASEDIR/20-check-artifacts-signed.sh --release

h1 "Step 9: Test MVP zip"
$RELEASE_BASEDIR/test-mvp-zip.sh --release

h1 "Step 10: Run GitHub Actions regression tests"
run_github_regression_tests

success "Automated release steps completed. Manual steps remain."
bold ""
bold "Next manual steps:"
bold "1. MEND scan (see release.md line 63)"
bold "2. Run Tekton regression tests (scripts 27-28)"
bold "3. Run the 'Deploy new Galasa version' workflow"
