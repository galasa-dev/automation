# Update the IBM Cloud Galasa external sites

1. Go to the argocd-ibmcloud repository 
1. Update the images with the correct version in:
   - default/javadoc-stable.yaml
   - default/restapidoc-stable.yaml
   - default/p2stable.yaml
   - default/resources.yaml
2. Let ArgoCD sync the `galasa-ibmcloud` application running on the internal cluster