#!/bin/bash

argocd app delete release-maven-repos
argocd app delete release-cli
argocd app delete prerelease-maven-repos
argocd app delete prerelease-cli

echo "Complete"