# Update the IBM Cloud Galasa external sites

1. Go to the argocd-ibmcloud repository 
1. Update the images with the correct version in:
   - default/javadoc-stable.yaml
   - default/p2stable.yaml
   - default/resources.yaml
1. Let ArgoCD sync (Application = galasa-ibmcloud)