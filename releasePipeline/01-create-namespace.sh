#!/bin/bash

set -e

kubectl create namespace galasa-release

kubectl get secret gpgkey --namespace=galasa-build -o json | jq 'del(.metadata.namespace,.metadata.resourceVersion,.metadata.uid, .metadata.creationTimestamp, .metadata.selfLink)' | kubectl apply --namespace=galasa-release -f -
kubectl get secret gpggradle --namespace=galasa-build -o json | jq 'del(.metadata.namespace,.metadata.resourceVersion,.metadata.uid, .metadata.creationTimestamp, .metadata.selfLink)' | kubectl apply --namespace=galasa-release -f -
kubectl get secret mavengpg --namespace=galasa-build -o json | jq 'del(.metadata.namespace,.metadata.resourceVersion,.metadata.uid, .metadata.creationTimestamp, .metadata.selfLink)' | kubectl apply --namespace=galasa-release -f -
kubectl get secret harbor-user-pass --namespace=galasa-build -o json | jq 'del(.metadata.namespace,.metadata.resourceVersion,.metadata.uid, .metadata.creationTimestamp, .metadata.selfLink)' | kubectl apply --namespace=galasa-release -f -
kubectl get secret galasadev-cert --namespace=galasa-build -o json | jq 'del(.metadata.namespace,.metadata.resourceVersion,.metadata.uid, .metadata.creationTimestamp, .metadata.selfLink)' | kubectl apply --namespace=galasa-release -f -
kubectl get secret github-creds --namespace=galasa-build -o json | jq 'del(.metadata.namespace,.metadata.resourceVersion,.metadata.uid, .metadata.creationTimestamp, .metadata.selfLink)' | kubectl apply --namespace=galasa-release -f -
kubectl get secret maven-creds --namespace=galasa-build -o json | jq 'del(.metadata.namespace,.metadata.resourceVersion,.metadata.uid, .metadata.creationTimestamp, .metadata.selfLink)' | kubectl apply --namespace=galasa-release -f -
kubectl get secret harbor-creds --namespace=galasa-build -o json | jq 'del(.metadata.namespace,.metadata.resourceVersion,.metadata.uid, .metadata.creationTimestamp, .metadata.selfLink)' | kubectl apply --namespace=galasa-release -f -
kubectl get secret dockerext-user-pass --namespace=galasa-build -o json | jq 'del(.metadata.namespace,.metadata.resourceVersion,.metadata.uid, .metadata.creationTimestamp, .metadata.selfLink)' | kubectl apply --namespace=galasa-release -f -
kubectl get secret ibmgithub --namespace=galasa-build -o json | jq 'del(.metadata.namespace,.metadata.resourceVersion,.metadata.uid, .metadata.creationTimestamp, .metadata.selfLink)' | kubectl apply --namespace=galasa-release -f -

echo "Complete"