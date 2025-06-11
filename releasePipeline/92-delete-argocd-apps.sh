#!/bin/bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#

argocd app delete release-maven-repos --grpc-web
argocd app delete release-bld --grpc-web
argocd app delete release-cli --grpc-web
argocd app delete release-simplatform --grpc-web
argocd app delete prerelease-maven-repos --grpc-web
argocd app delete prerelease-bld --grpc-web
argocd app delete prerelease-cli --grpc-web
argocd app delete prerelease-simplatform --grpc-web

echo "Complete"