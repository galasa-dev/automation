#!/bin/bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#

# Delete ArgoCD apps, ignoring errors if they don't exist
argocd app delete release-maven-repos --grpc-web --yes 2>/dev/null || true
argocd app delete release-bld --grpc-web --yes 2>/dev/null || true
argocd app delete release-cli --grpc-web --yes 2>/dev/null || true
argocd app delete release-simplatform --grpc-web --yes 2>/dev/null || true
argocd app delete prerelease-maven-repos --grpc-web --yes 2>/dev/null || true
argocd app delete prerelease-bld --grpc-web --yes 2>/dev/null || true
argocd app delete prerelease-cli --grpc-web --yes 2>/dev/null || true
argocd app delete prerelease-simplatform --grpc-web --yes 2>/dev/null || true

echo "ArgoCD apps cleanup complete"