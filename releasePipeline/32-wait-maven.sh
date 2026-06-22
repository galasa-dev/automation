#!/bin/bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#
#-----------------------------------------------------------------------------------------
#
# Objectives: Wait for a specific Galasa version to appear in Maven Central
#
# Usage: 32-wait-maven.sh [--version <version>] [--sleep <seconds>] [--max-iterations <count>]
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
version=""
sleep_seconds=60
max_iterations=60

function usage {
    info "Usage: 32-wait-maven.sh [--version <version>] [--sleep <seconds>] [--max-iterations <count>]"
    info ""
    info "Optional parameters:"
    info "  --version           Galasa version to wait for (if not provided, just displays current metadata)"
    info "  --sleep             Seconds to wait between checks (default: 30)"
    info "  --max-iterations    Maximum number of check iterations (default: 40)"
}

while [ "$1" != "" ]; do
    case $1 in
        --version )             shift
                                version=$1
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

#-----------------------------------------------------------------------------------------
# Main logic
#-----------------------------------------------------------------------------------------

maven_metadata_url="https://repo.maven.apache.org/maven2/dev/galasa/galasa-bom/maven-metadata.xml"

if [[ -z "$version" ]]; then
    # No version specified - just watch the metadata (original behavior)
    info "No version specified - watching Maven Central metadata..."
    info "Press Ctrl+C to exit"
    watch -n "$sleep_seconds" curl "$maven_metadata_url"
else
    # Version specified - poll until it appears
    h2 "Waiting for Galasa version $version to appear in Maven Central"
    info "Polling: $maven_metadata_url"
    info "Checking every $sleep_seconds seconds (max $max_iterations attempts)"
    
    counter=0
    
    while [[ $counter -lt $max_iterations ]]; do
        info "Checking Maven Central... (attempt $((counter+1))/$max_iterations)"
        
        # Fetch the metadata
        metadata=$(curl -sf "$maven_metadata_url" 2>&1)
        
        if [[ $? -ne 0 ]]; then
            warn "Failed to fetch Maven Central metadata: $metadata"
            info "Waiting $sleep_seconds seconds before retrying..."
            sleep "$sleep_seconds"
            ((counter++))
            continue
        fi
        
        # Check if the version appears in the metadata
        if echo "$metadata" | grep -q "<version>$version</version>"; then
            success "Galasa version $version found in Maven Central!"
            info "Metadata URL: $maven_metadata_url"
            exit 0
        fi
        
        info "Version $version not yet available in Maven Central"
        info "Waiting $sleep_seconds seconds before checking again..."
        sleep "$sleep_seconds"
        ((counter++))
    done
    
    error "Timeout waiting for version $version to appear in Maven Central"
    error "Check $maven_metadata_url manually"
    exit 1
fi