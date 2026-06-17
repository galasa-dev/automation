#!/usr/bin/env bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#
#-----------------------------------------------------------------------------------------                   
#
# Objectives: Wait for a GitHub Actions workflow to complete
#
# Usage: wait-for-workflow.sh --repo <owner/repo> --workflow <file> --branch <name> --start-time <timestamp> --name <display-name> [--sleep <seconds>] [--max-iterations <count>]
#
#-----------------------------------------------------------------------------------------     

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
# Process parameters
#-----------------------------------------------------------------------------------------
repo=""
workflow_file=""
branch=""
start_time=""
workflow_name=""
sleep_seconds=60
max_iterations=50

function usage {
    info "Usage: wait-for-workflow.sh --repo <owner/repo> --workflow <file> --branch <name> --start-time <timestamp> --name <display-name> [--sleep <seconds>] [--max-iterations <count>]"
    info ""
    info "Required parameters:"
    info "  --repo              GitHub repository in format 'owner/repo' (e.g., 'galasa-dev/isolated')"
    info "  --workflow          Workflow filename (e.g., 'build.yaml')"
    info "  --branch            Branch name to monitor (e.g., 'release', 'prerelease')"
    info "  --start-time        ISO 8601 timestamp to filter workflows created after this time"
    info "  --name              Human-readable name for logging (e.g., 'Isolated build')"
    info ""
    info "Optional parameters:"
    info "  --sleep             Seconds to wait between checks (default: 60)"
    info "  --max-iterations    Maximum number of check iterations (default: 50)"
}

while [ "$1" != "" ]; do
    case $1 in
        --repo )                shift
                                repo=$1
                                ;;
        --workflow )            shift
                                workflow_file=$1
                                ;;
        --branch )              shift
                                branch=$1
                                ;;
        --start-time )          shift
                                start_time=$1
                                ;;
        --name )                shift
                                workflow_name=$1
                                ;;
        --sleep )               shift
                                sleep_seconds=$1
                                ;;
        --max-iterations )      shift
                                max_iterations=$1
                                ;;
        -h | --help )           usage
                                exit 0
                                ;;
        * )                     error "Unexpected argument $1"
                                usage
                                exit 1
    esac
    shift
done

# Validate required parameters
if [[ -z "$repo" || -z "$workflow_file" || -z "$branch" || -z "$start_time" || -z "$workflow_name" ]]; then
    error "Missing required parameters"
    usage
    exit 1
fi

#-----------------------------------------------------------------------------------------
# Main logic
#-----------------------------------------------------------------------------------------

h2 "Waiting for ${workflow_name} to complete"

counter=0

info "Looking for ${workflow_name} workflows created after: ${start_time}"
info "Repository: ${repo}, Workflow: ${workflow_file}, Branch: ${branch}"

while [[ $counter -lt $max_iterations ]]; do
    info "Checking for ${workflow_name} workflow... (attempt $((counter+1))/$max_iterations)"
    
    # Get workflow runs for the specified branch created after our start time
    run_data=$(gh run list --repo "${repo}" --workflow "${workflow_file}" --branch "${branch}" --limit 5 --json databaseId,createdAt,conclusion 2>&1)
    
    # Check if the command succeeded
    if [[ $? -ne 0 ]]; then
        warn "Failed to query workflow runs: ${run_data}"
        sleep $sleep_seconds || true
        ((counter++)) || true
        continue
    fi
    
    # Validate JSON data
    if ! echo "$run_data" | jq empty 2>/dev/null; then
        warn "Invalid JSON response from GitHub API"
        sleep $sleep_seconds || true
        ((counter++)) || true
        continue
    fi
    
    # Find the first run created after our start time
    run_id=$(echo "$run_data" | jq -r --arg start_time "$start_time" '.[] | select(.createdAt > $start_time) | .databaseId' 2>/dev/null | head -1)
    
    if [[ -n "$run_id" ]]; then
        info "Found ${workflow_name} workflow run: ${run_id}"
        
        # Get the full status of this specific run
        run_info=$(echo "$run_data" | jq -r --arg run_id "$run_id" '.[] | select(.databaseId == ($run_id | tonumber))')
        status=$(echo "$run_info" | jq -r '.conclusion')
        created_at=$(echo "$run_info" | jq -r '.createdAt')
        
        info "Workflow created at: ${created_at}"
        
        if [[ "$status" == "success" ]]; then
            success "${workflow_name} completed successfully."
            info "View at: https://github.com/${repo}/actions/runs/${run_id}"
            exit 0
        elif [[ "$status" == "failure" || "$status" == "cancelled" ]]; then
            error "${workflow_name} failed or was cancelled."
            error "Check https://github.com/${repo}/actions/runs/${run_id}"
            exit 1
        elif [[ "$status" == "null" || -z "$status" ]]; then
            info "${workflow_name} status: in_progress"
        else
            info "${workflow_name} status: ${status}"
        fi
    else
        info "${workflow_name} workflow not yet started (no runs found after ${start_time})..."
    fi
    
    # Sleep before next check
    info "Waiting for ${sleep_seconds} seconds before checking again..."
    sleep $sleep_seconds || true
    ((counter++)) || true
done

error "Timed out waiting for ${workflow_name} to complete"
error "Check https://github.com/${repo}/actions for status"
exit 1
