#!/usr/bin/env bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#
#-----------------------------------------------------------------------------------------                   
#
# Objectives: Run all the pre-release steps 
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

function wait_for_isolated_build {
    h2 "Waiting for Isolated build to complete"
    
    local start_time="$1"
    MAX_WAIT_ITERATIONS=50
    COUNTER=0
    release_type="prerelease"
    SLEEP_TIME_SECONDS=120
    
    info "Looking for Isolated builds created after: ${start_time}"
    
    while [[ $COUNTER -lt $MAX_WAIT_ITERATIONS ]]; do
        info "Checking for Isolated build workflow... (attempt $((COUNTER+1))/$MAX_WAIT_ITERATIONS)"
        
        # Get workflow runs for the prerelease branch created after our start time
        run_data=$(gh run list --repo galasa-dev/isolated --workflow build.yaml --branch ${release_type} --limit 5 --json databaseId,createdAt,conclusion 2>&1)
        
        # Check if the command succeeded
        if [[ $? -ne 0 ]]; then
            warn "Failed to query workflow runs: ${run_data}"
            continue
        fi
        
        # Validate JSON data
        if ! echo "$run_data" | jq empty 2>/dev/null; then
            warn "Invalid JSON response from GitHub API"
            continue
        fi
        
        # Find the first run created after our start time
        run_id=$(echo "$run_data" | jq -r --arg start_time "$start_time" '.[] | select(.createdAt > $start_time) | .databaseId' 2>/dev/null | head -1)
        
        if [[ -n "$run_id" ]]; then
            info "Found Isolated build workflow run: ${run_id}"
            
            # Get the full status of this specific run
            run_info=$(echo "$run_data" | jq -r --arg run_id "$run_id" '.[] | select(.databaseId == ($run_id | tonumber))')
            status=$(echo "$run_info" | jq -r '.conclusion')
            created_at=$(echo "$run_info" | jq -r '.createdAt')
            
            info "Workflow created at: ${created_at}"
            
            if [[ "$status" == "success" ]]; then
                success "Isolated build completed successfully."
                info "View at: https://github.com/galasa-dev/isolated/actions/runs/${run_id}"
                return 0
            elif [[ "$status" == "failure" || "$status" == "cancelled" ]]; then
                error "Isolated build failed or was cancelled."
                error "Check https://github.com/galasa-dev/isolated/actions/runs/${run_id}"
                exit 1
            elif [[ "$status" == "null" || -z "$status" ]]; then
                info "Isolated build status: in_progress"
            else
                info "Isolated build status: ${status}"
            fi
        else
            info "Isolated build workflow not yet started (no runs found after ${start_time})..."
        fi
        
        # Sleep before next check
        info "Waiting for ${SLEEP_TIME_SECONDS} seconds before checking again..."
        sleep $SLEEP_TIME_SECONDS || true
        ((COUNTER++)) || true
    done
    
    error "Timed out waiting for Isolated build to complete"
    error "Check https://github.com/galasa-dev/isolated/actions for status"
    exit 1
}

function wait_for_webui_build {
    h2 "Waiting for Web UI build to complete"
    
    local start_time="$1"
    MAX_WAIT_ITERATIONS=50
    COUNTER=0
    release_type="prerelease"
    SLEEP_TIME_SECONDS=60
    
    info "Looking for Web UI builds created after: ${start_time}"
    
    while [[ $COUNTER -lt $MAX_WAIT_ITERATIONS ]]; do
        info "Checking for Web UI build workflow... (attempt $((COUNTER+1))/$MAX_WAIT_ITERATIONS)"
        
        # Get workflow runs for the prerelease branch created after our start time
        run_data=$(gh run list --repo galasa-dev/webui --workflow build.yaml --branch ${release_type} --limit 5 --json databaseId,createdAt,conclusion 2>&1)
        
        # Check if the command succeeded
        if [[ $? -ne 0 ]]; then
            warn "Failed to query workflow runs: ${run_data}"
            continue
        fi
        
        # Validate JSON data
        if ! echo "$run_data" | jq empty 2>/dev/null; then
            warn "Invalid JSON response from GitHub API"
            continue
        fi
        
        # Find the first run created after our start time
        run_id=$(echo "$run_data" | jq -r --arg start_time "$start_time" '.[] | select(.createdAt > $start_time) | .databaseId' 2>/dev/null | head -1)
        
        if [[ -n "$run_id" ]]; then
            info "Found Web UI build workflow run: ${run_id}"
            
            # Get the full status of this specific run
            run_info=$(echo "$run_data" | jq -r --arg run_id "$run_id" '.[] | select(.databaseId == ($run_id | tonumber))')
            status=$(echo "$run_info" | jq -r '.conclusion')
            created_at=$(echo "$run_info" | jq -r '.createdAt')
            
            info "Workflow created at: ${created_at}"
            
            if [[ "$status" == "success" ]]; then
                success "Web UI build completed successfully."
                info "View at: https://github.com/galasa-dev/webui/actions/runs/${run_id}"
                return 0
            elif [[ "$status" == "failure" || "$status" == "cancelled" ]]; then
                error "Web UI build failed or was cancelled."
                error "Check https://github.com/galasa-dev/webui/actions/runs/${run_id}"
                exit 1
            elif [[ "$status" == "null" || -z "$status" ]]; then
                info "Web UI build status: in_progress"
            else
                info "Web UI build status: ${status}"
            fi
        else
            info "Web UI build workflow not yet started (no runs found after ${start_time})..."
        fi
        
        # Sleep before next check
        info "Waiting for ${SLEEP_TIME_SECONDS} seconds before checking again..."
        sleep $SLEEP_TIME_SECONDS || true
        ((COUNTER++)) || true
    done
    
    error "Timed out waiting for Web UI build to complete"
    error "Check https://github.com/galasa-dev/webui/actions for status"
    exit 1
}

#-----------------------------------------------------------------------------------------
# Main Program
#-----------------------------------------------------------------------------------------
set -e

h1 "run 02-create-argocd-apps.sh"
$RELEASE_BASEDIR/02-create-argocd-apps.sh --prerelease

h1 "run 03-repo-branches-delete.sh"
$RELEASE_BASEDIR/03-repo-branches-delete.sh --prerelease

# Capture timestamp before creating branches
# This ensures we can identify workflows triggered by the branch creation
BRANCH_CREATE_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
info "Branch creation time: ${BRANCH_CREATE_TIME}"

h1 "run 04-repo-branches-create.sh"
$RELEASE_BASEDIR/04-repo-branches-create.sh --prerelease

h1 "run 05-helm-charts.sh"
$RELEASE_BASEDIR/05-helm-charts.sh --prerelease --start-time "${BRANCH_CREATE_TIME}"

h1 "run 10-build-galasa-mono-repo.sh"

# Capture the current time before starting the build
# This ensures we only wait for workflows created after this point
BUILD_START_TIME="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
info "Build start time: ${BUILD_START_TIME}"

$RELEASE_BASEDIR/10-build-galasa-mono-repo.sh --prerelease --wait

h1 "Waiting for downstream builds to complete"
wait_for_isolated_build "${BUILD_START_TIME}"
wait_for_webui_build "${BUILD_START_TIME}"

h1 "run 20-check-artifacts-signed.sh"
$RELEASE_BASEDIR/20-check-artifacts-signed.sh --prerelease

success "Pre-release automation completed successfully!"
