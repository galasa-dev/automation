# Argocd
This folder holds content which is kept in-sync with the 'live' system by Argocd

The live system is on the external IBM cloud, in the galasa-cluster kubernetes system, in the galasa-pipelines namespace.

An ArgoCD application called github-webhook-receiver syncs this folder up with the kube system.
