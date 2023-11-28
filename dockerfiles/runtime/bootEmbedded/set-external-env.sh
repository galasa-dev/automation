#!/bin/bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#
#--------------------------------------------------------------------------
#
# Objective: Set environment variables for external ecosystem services
#
#--------------------------------------------------------------------------

#
# Functions
#
function usage {
  echo "usage: set-external-env.sh [OPTIONS]"
  cat << EOF
Options are:
--hostname <host_name> : The name/IP of the host running the ecosystem (mandatory).
--prefix <service_prefix> : The prefix of the external services.
-h | --help : Display usage information.
EOF
  return 0
}

function get_external_port {
  serviceName="$1-external"
  portName=$2
  port=""

  # Wait for the external service to be assigned a port
  maxRetries=10
  retriesLeft=${maxRetries}
  while [[ -z "${port}" && ${retriesLeft} -ne 0 ]]; do
    port=$(kubectl get svc ${serviceName} -o=jsonpath="{.spec.ports[?(@.name==\"${portName}\")].nodePort}")
    [ -z "${port}" ] && sleep 1 && retriesLeft=$((retriesLeft-1))
  done

  if [[ -z "${port}" ]]; then
    echo 1>&2 "Error: Failed to retrieve port for ${serviceName} after ${maxRetries} tries."
    return 1
  fi
  echo "${port}"
  return 0
}

#
# Process arguments
#
hostName=""
prefix=""

while [ "$1" != "" ]; do
  case $1 in
    --hostname )      shift
                      hostName="$1"
                      ;;
    --prefix )        shift
                      prefix="$1"
                      ;;
    -h | --help )     usage
                      return
                      ;;                    
    * )               echo "Unexpected argument $1"
                      usage
                      return 1
  esac
  shift
done

if [[ -z "${hostName}" ]]; then
  echo "Error: Please specify --hostname <host_name>."
  usage
  return 1
fi

echo "HOSTNAME is ${hostName}"
echo "PREFIX is ${prefix}"

#
# Retrieve the port numbers of the Services for external access
#
echo "Retrieving external service ports..."
etcdPort=$(get_external_port "${prefix}etcd" "client")
couchdbPort=$(get_external_port "${prefix}couchdb" "http")

echo "ETCD port is ${etcdPort}"
echo "COUCHDB port is ${couchdbPort}"

#
# Set environment variables for external services
#
echo "Setting environment variables..."
export GALASA_EXTERNAL_RESULTARCHIVE_STORE="couchdb:http://${hostName}:${couchdbPort}"
export GALASA_EXTERNAL_ETCD_STORE="etcd:http://${hostName}:${etcdPort}"
export GALASA_EXTERNAL_DYNAMICSTATUS_STORE=${GALASA_EXTERNAL_ETCD_STORE}
export GALASA_EXTERNAL_CREDENTIALS_STORE=${GALASA_EXTERNAL_ETCD_STORE}

echo "DSS is ${GALASA_EXTERNAL_DYNAMICSTATUS_STORE}"
echo "RAS is ${GALASA_EXTERNAL_RESULTARCHIVE_STORE}"
echo "CREDS is ${GALASA_EXTERNAL_CREDENTIALS_STORE}"