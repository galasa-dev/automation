#!/bin/bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#

argocd app delete release-maven-repos
argocd app delete release-cli
argocd app delete release-simplatform
argocd app delete prerelease-maven-repos
argocd app delete prerelease-cli
argocd app delete prerelease-simplatform

echo "Complete"