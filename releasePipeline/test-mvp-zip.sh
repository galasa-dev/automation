#!/usr/bin/env bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#

set -e

#-----------------------------------------------------------------------------
# Script to automate testing of the Galasa MVP zip
#
# This script:
# 1. Downloads the MVP zip from the specified repository (release or prerelease)
# 2. Extracts the zip and validates the isolated.tar Docker image
# 3. Loads and runs the Docker image, verifying the web interface
# 4. Runs SimBank tests using the extracted maven repository
#-----------------------------------------------------------------------------

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
REPO_TYPE="release"
WORK_DIR="$(pwd)/temp/mvp-test-$(date +%s)"
CONTAINER_NAME="galasa-mvp-test"
DOCKER_IMAGE=""

#-----------------------------------------------------------------------------
# Functions
#-----------------------------------------------------------------------------

function usage {
    echo "Syntax: $0 [OPTIONS]"
    cat << EOF
Options are:
  --release       Download from release repository (default)
  --prerelease    Download from prerelease repository
  --main          Download from main repository
  --work-dir      Specify working directory (default: ./temp/mvp-test-<timestamp>)
  --help          Display this help message

Examples:
  $0 --release
  $0 --prerelease
  $0 --main

Environment variables:
None
EOF
    exit 1
}

function log_info {
    echo -e "${BLUE}[INFO]${NC} $1"
}

function log_success {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

function log_warning {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

function log_error {
    echo -e "${RED}[ERROR]${NC} $1"
}

function cleanup {
    log_info "Cleaning up..."
    
    # Kill any running SimPlatform processes
    if pgrep -f "galasa-simplatform.*\.jar" >/dev/null 2>&1; then
        log_info "Stopping SimPlatform processes..."
        pkill -f "galasa-simplatform.*\.jar" || true
        sleep 2
    fi
    
    # Stop and remove Docker container if running
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "Stopping and removing Docker container: ${CONTAINER_NAME}"
        docker stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
        docker rm "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    fi
    
    # Remove Docker image if it exists
    if [ -n "${DOCKER_IMAGE}" ] && docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${DOCKER_IMAGE}$"; then
        log_info "Removing Docker image: ${DOCKER_IMAGE}"
        docker rmi "${DOCKER_IMAGE}" >/dev/null 2>&1 || true
    fi
    
    log_success "Cleanup complete"
}

function get_galasa_version {
    log_info "Detecting Galasa version from galasa repository..."
    
    # Download build.properties directly from GitHub
    local build_props_url="https://raw.githubusercontent.com/galasa-dev/galasa/main/build.properties"
    local temp_file=$(mktemp)
    
    if ! curl -f -s -o "${temp_file}" "${build_props_url}"; then
        log_error "Failed to download build.properties from ${build_props_url}"
        rm -f "${temp_file}"
        exit 1
    fi
    
    if [ -f "${temp_file}" ]; then
        GALASA_VERSION=$(grep "GALASA_VERSION=" "${temp_file}" | cut -d'=' -f2)
        if [ -z "${GALASA_VERSION}" ]; then
            log_error "Could not extract GALASA_VERSION from build.properties"
            rm -f "${temp_file}"
            exit 1
        fi
        log_success "Detected Galasa version: ${GALASA_VERSION}"
    else
        log_error "Could not find build.properties file"
        rm -f "${temp_file}"
        exit 1
    fi
    
    rm -f "${temp_file}"
}

function download_mvp_zip {
    local base_url="https://development.galasa.dev/${REPO_TYPE}/maven-repo/mvp/dev/galasa/galasa-isolated-mvp"
    local zip_url="${base_url}/${GALASA_VERSION}/galasa-isolated-mvp-${GALASA_VERSION}.zip"
    
    log_info "Downloading MVP zip from ${REPO_TYPE} repository..."
    log_info "URL: ${zip_url}"
    
    mkdir -p "${WORK_DIR}"
    cd "${WORK_DIR}"
    
    if ! curl -f -L -o "galasa-isolated-mvp-${GALASA_VERSION}.zip" "${zip_url}"; then
        log_error "Failed to download MVP zip from ${zip_url}"
        exit 1
    fi
    
    log_success "Downloaded MVP zip successfully"
}

function extract_mvp_zip {
    log_info "Extracting MVP zip..."
    
    cd "${WORK_DIR}"
    
    if ! unzip -q "galasa-isolated-mvp-${GALASA_VERSION}.zip"; then
        log_error "Failed to extract MVP zip"
        exit 1
    fi
    
    log_success "Extracted MVP zip successfully"
    
    # Verify expected structure - files extract directly to work directory
    if [ ! -f "isolated.tar" ]; then
        log_error "Expected 'isolated.tar' file not found after extraction"
        exit 1
    fi
    
    if [ ! -f "run-simplatform.sh" ]; then
        log_error "Expected 'run-simplatform.sh' file not found after extraction"
        exit 1
    fi
    
    if [ ! -d "maven" ]; then
        log_error "Expected 'maven' directory not found after extraction"
        exit 1
    fi
    
    if [ ! -d "galasactl" ]; then
        log_error "Expected 'galasactl' directory not found after extraction"
        exit 1
    fi
    
    log_success "Verified MVP zip structure"
}

function load_docker_image {
    log_info "Loading Docker image from isolated.tar..."
    
    cd "${WORK_DIR}"
    
    local output
    output=$(docker load -i isolated.tar 2>&1)
    
    echo "${output}"
    
    # Extract the actual image name from the output
    if echo "${output}" | grep -q "Loaded image:"; then
        DOCKER_IMAGE=$(echo "${output}" | grep "Loaded image:" | sed 's/Loaded image: //')
        log_success "Docker image loaded successfully: ${DOCKER_IMAGE}"
    else
        log_error "Failed to load Docker image"
        log_error "Output: ${output}"
        exit 1
    fi
}

function run_docker_container {
    log_info "Starting Docker container..."
    
    # Check if port 8080 is already in use
    if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
        log_error "Port 8080 is already in use. Please free the port and try again."
        exit 1
    fi
    
    if ! docker run -d -p 8080:80 --name "${CONTAINER_NAME}" "${DOCKER_IMAGE}"; then
        log_error "Failed to start Docker container"
        exit 1
    fi
    
    log_success "Docker container started: ${CONTAINER_NAME}"
    
    # Wait for container to be ready
    log_info "Waiting for container to be ready..."
    sleep 5
    
    # Verify container is running
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_error "Container is not running"
        docker logs "${CONTAINER_NAME}"
        exit 1
    fi
    
    log_success "Container is running"
}

function verify_web_interface {
    log_info "Verifying web interface at http://localhost:8080..."
    
    local max_attempts=10
    local attempt=1
    
    while [ ${attempt} -le ${max_attempts} ]; do
        if curl -f -s http://localhost:8080 >/dev/null 2>&1; then
            log_success "Web interface is accessible at http://localhost:8080"
            return 0
        fi
        
        log_warning "Attempt ${attempt}/${max_attempts}: Web interface not yet accessible, retrying..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log_error "Web interface is not accessible after ${max_attempts} attempts"
    exit 1
}

function setup_galasactl {
    log_info "Setting up galasactl from MVP zip..."
    
    cd "${WORK_DIR}"
    
    if [ ! -d "galasactl" ]; then
        log_error "galasactl directory not found"
        exit 1
    fi
    
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)
    
    # Map architecture names
    if [ "${arch}" = "x86_64" ]; then
        arch="x86_64"
    elif [ "${arch}" = "arm64" ] || [ "${arch}" = "aarch64" ]; then
        arch="arm64"
    fi
    
    local galasactl_binary="galasactl/galasactl-${os}-${arch}"
    
    if [ ! -f "${galasactl_binary}" ]; then
        log_error "galasactl binary not found: ${galasactl_binary}"
        log_info "Available files in galasactl directory:"
        ls -la galasactl/
        exit 1
    fi
    
    # Create symlink for easier access
    mkdir -p "${WORK_DIR}/bin"
    ln -sf "${WORK_DIR}/${galasactl_binary}" "${WORK_DIR}/bin/galasactl"
    chmod +x "${WORK_DIR}/bin/galasactl"
    
    # Remove quarantine attribute on macOS
    if [ "${os}" = "darwin" ]; then
        xattr -dr com.apple.quarantine "${WORK_DIR}/bin/galasactl" 2>/dev/null || true
    fi
    
    log_success "galasactl set up successfully from MVP zip"
}

function initialize_galasa {
    log_info "Initializing Galasa environment..."
    
    cd "${WORK_DIR}"
    export GALASA_HOME="${WORK_DIR}/.galasa"
    
    if ! ./bin/galasactl local init --log -; then
        log_error "Failed to initialize Galasa environment"
        exit 1
    fi
    
    log_success "Galasa environment initialized"
    
    # Create cps.properties
    log_info "Creating cps.properties..."
    cat > "${GALASA_HOME}/cps.properties" << 'EOF'
#
# File: cps.properties
#
# Purpose:
#   To provide properties to the Galasa runtime when running tests in a local JVM.
#

simbank.dse.instance.name=SIMBANK
simbank.instance.SIMBANK.zos.image=SIMBANK
simbank.instance.SIMBANK.credentials.id=SIMBANK

zos.dse.tag.SIMBANK.imageid=SIMBANK
zos.image.SIMBANK.ipv4.hostname=127.0.0.1
zos.image.SIMBANK.telnet.tls=false
zos.image.SIMBANK.telnet.port=2023
zos.image.SIMBANK.webnet.port=2080
zos.image.SIMBANK.credentials=SIMBANK

zosmf.server.SIMBANK.images=SIMBANK
zosmf.server.SIMBANK.hostname=127.0.0.1
zosmf.server.SIMBANK.port=2040
zosmf.server.SIMBANK.https=false
EOF
    
    log_success "Created cps.properties"
    
    # Create credentials.properties
    log_info "Creating credentials.properties..."
    cat > "${GALASA_HOME}/credentials.properties" << 'EOF'
#
# File: credentials.properties
#
# Purpose:
#   To provide credentials to the Galasa runtime when running tests in a local JVM.
#   These credentials are for the demo Simplatform application.
#

secure.credentials.SIMBANK.username=IBMUSER
secure.credentials.SIMBANK.password=SYS1
EOF
    
    log_success "Created credentials.properties"
}

function start_simplatform {
    log_info "Starting SimPlatform application..."
    
    # Check if SimPlatform is already running
    if pgrep -f "galasa-simplatform.*\.jar" >/dev/null 2>&1; then
        log_warning "SimPlatform appears to be already running. Stopping existing processes..."
        pkill -f "galasa-simplatform.*\.jar" >/dev/null 2>&1 || true
        sleep 3
    fi
    
    cd "${WORK_DIR}"
    
    if [ ! -f "run-simplatform.sh" ]; then
        log_error "run-simplatform.sh not found"
        exit 1
    fi
    
    chmod +x run-simplatform.sh
    
    # Start SimPlatform in background using the --server flag and --location
    # Redirect stderr to filter out the expected exit code 143 message from previous runs
    ./run-simplatform.sh --server --location "${WORK_DIR}/maven/dev/galasa" > "${WORK_DIR}/simplatform.log" 2>&1 &
    local simplatform_pid=$!
    
    log_info "SimPlatform started with PID: ${simplatform_pid}"
    log_info "SimPlatform logs: ${WORK_DIR}/simplatform.log"
    
    # Wait for SimPlatform to be ready
    log_info "Waiting for SimPlatform to be ready..."
    sleep 10
    
    # Verify SimPlatform is still running
    if ! kill -0 ${simplatform_pid} 2>/dev/null; then
        log_error "SimPlatform process is not running"
        log_error "Last 20 lines of SimPlatform log:"
        tail -20 "${WORK_DIR}/simplatform.log"
        exit 1
    fi
    
    log_success "SimPlatform is running"
}

function run_simbank_tests {
    log_info "Running SimBank tests..."
    
    cd "${WORK_DIR}"
    export GALASA_HOME="${WORK_DIR}/.galasa"
    
    local maven_repo="${WORK_DIR}/maven"
    
    if [ ! -d "${maven_repo}" ]; then
        log_error "Maven repository not found at: ${maven_repo}"
        exit 1
    fi
    
    log_info "Using local maven repository: ${maven_repo}"
    
    local tests=(
        "dev.galasa.simbank.tests.SimBankIVT"
        "dev.galasa.simbank.tests.BasicAccountCreditTest"
        "dev.galasa.simbank.tests.ProvisionedAccountCreditTests"
        "dev.galasa.simbank.tests.BatchAccountsOpenTest"
    )
    
    local test_num=1
    local failed_tests=()
    
    for test_class in "${tests[@]}"; do
        log_info "Running test ${test_num}/${#tests[@]}: ${test_class}"
        
        if ./bin/galasactl runs submit local \
            --obr mvn:dev.galasa/dev.galasa.simbank.obr/${GALASA_VERSION}/obr \
            --obr mvn:dev.galasa/dev.galasa.uber.obr/${GALASA_VERSION}/obr \
            --class "dev.galasa.simbank.tests/${test_class}" \
            --localMaven "file://${maven_repo}" \
            --reportjson "${GALASA_HOME}/test-${test_num}.json" \
            --log -; then
            log_success "Test passed: ${test_class}"
        else
            log_error "Test failed: ${test_class}"
            failed_tests+=("${test_class}")
        fi
        
        test_num=$((test_num + 1))
    done
    
    # Report results
    echo ""
    log_info "=========================================="
    log_info "Test Results Summary"
    log_info "=========================================="
    log_info "Total tests: ${#tests[@]}"
    log_info "Passed: $((${#tests[@]} - ${#failed_tests[@]}))"
    log_info "Failed: ${#failed_tests[@]}"
    
    if [ ${#failed_tests[@]} -gt 0 ]; then
        log_error "Failed tests:"
        for test in "${failed_tests[@]}"; do
            log_error "  - ${test}"
        done
        return 1
    else
        log_success "All tests passed!"
        return 0
    fi
}

#-----------------------------------------------------------------------------
# Main script
#-----------------------------------------------------------------------------

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --release)
            REPO_TYPE="release"
            shift
            ;;
        --prerelease)
            REPO_TYPE="prerelease"
            shift
            ;;
        --main)
            REPO_TYPE="main"
            shift
            ;;
        --work-dir)
            WORK_DIR="$2"
            shift 2
            ;;
        --help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Trap to cleanup on exit
trap cleanup EXIT

log_info "=========================================="
log_info "Galasa MVP Zip Test Script"
log_info "=========================================="
log_info "Repository type: ${REPO_TYPE}"
log_info "Working directory: ${WORK_DIR}"
echo ""

# Execute test steps
mkdir -p temp
get_galasa_version
download_mvp_zip
extract_mvp_zip
load_docker_image
run_docker_container
verify_web_interface
setup_galasactl
initialize_galasa
start_simplatform
run_simbank_tests

log_success "=========================================="
log_success "MVP zip testing completed successfully!"
log_success "=========================================="
