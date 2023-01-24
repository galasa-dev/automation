#!/bin/bash

argocd app delete release-maven-repos
argocd app delete release-cli

echo "Complete"