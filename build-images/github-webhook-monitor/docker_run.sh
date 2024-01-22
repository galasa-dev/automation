#!/usr/bin/env bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#

ORG_NAME="galasa-dev"
HOOK_ID="386623630"

docker run \
    -v $(pwd)/config.yaml:/config.yaml \
    -v $(pwd)/latestId:/latestId \
    -e GITHUBTOKEN=${GITHUBTOKEN} \
    github-monitor:latest -org=${ORG_NAME} -hook=${HOOK_ID} -trigger-map=/config.yaml