# Update the IBM Cloud Galasa external sites

1. Push a commit to argocd-ibmcloud repository with default/javadoc-stable.yaml default/p2stable.yaml default/resources.yaml pointing to the new version.
1. Let ArgoCD sync, application = galasa-ibmcloud