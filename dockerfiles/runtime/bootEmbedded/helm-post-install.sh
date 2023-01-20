#!/bin/bash

set -e

#
# Functions
#
function usage {
    echo "usage: helm-post-install.sh [OPTIONS]"
    cat << EOF
Options are:
--hostname <host_name> : The name/IP of the host running the ecosystem (mandatory).
--prefix <service_prefix> : The prefix of the external services.
-h | --help : Display usage information.
EOF
}

function get_external_port() {
  serviceName=$1
  portName=$2
  port=""
  externalService="${PREFIX}${serviceName}-external"

  # Wait for the external service to be assigned a port
  maxRetries=10
  retriesLeft=${maxRetries}
  while [[ -z "${port}" && ${retriesLeft} -ne 0 ]]; do
    port=$(kubectl get svc ${externalService} -o=jsonpath="{.spec.ports[?(@.name==\"${portName}\")].nodePort}")
    [ -z "${port}" ] && sleep 1 && retriesLeft=$((retriesLeft-1))
  done

  if [[ -z "${port}" ]]; then
      echo 1>&2 "Error: Failed to retrieve port for ${externalService} after ${maxRetries} tries."
      usage
      exit 1
  fi
  echo "${port}"
}

#
# Process arguments
#
HOSTNAME=""
PREFIX=""

while [ "$1" != "" ]; do
  case $1 in
    --hostname )      shift
                      HOSTNAME="$1"
                      ;;
    --prefix )        shift
                      PREFIX="$1"
                      ;;
    -h | --help )     usage
                      exit
                      ;;                    
    * )               echo "Unexpected argument $1"
                      usage
                      exit 1
  esac
  shift
done

if [ -z "${HOSTNAME}" ]
  then
    echo "Error: Please specify --hostname <host_name>."
    usage
    exit 1
fi

echo "HOSTNAME is ${HOSTNAME}"
echo "PREFIX is ${PREFIX}"

#
# Retrieve the port numbers of the Services for external access
#
echo "Retrieving external service ports..."
ETCDPORT=$(get_external_port "etcd" "client")
COUCHDBPORT=$(get_external_port "couchdb" "http")

echo "ETCD port is ${ETCDPORT}"
echo "COUCHDB port is ${COUCHDBPORT}"

#
# Set environment variables for external services
#
echo "Setting environment variables..."
export GALASA_EXTERNAL_DYNAMICSTATUS_STORE="etcd:http://${HOSTNAME}:${ETCDPORT}"
export GALASA_EXTERNAL_RESULTARCHIVE_STORE="couchdb:http://${HOSTNAME}:${COUCHDBPORT}"
export GALASA_EXTERNAL_CREDENTIALS_STORE="etcd:http://${HOSTNAME}:${ETCDPORT}"

echo "DSS is ${GALASA_EXTERNAL_DYNAMICSTATUS_STORE}"
echo "RAS is ${GALASA_EXTERNAL_RESULTARCHIVE_STORE}"
echo "CREDS is ${GALASA_EXTERNAL_CREDENTIALS_STORE}"