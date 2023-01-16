#!/bin/bash

argocd app delete galasa-release-repo
argocd app delete cli-release-repo

echo "Complete"