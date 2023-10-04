# Update the IBM Cloud Galasa external sites

1. Go to the definitions for the production sites in the infrastructure/galasa-plan-b-lon02/galasa-production/galasa-production.
1. Update the images with the correct version for this release in the following files:
   - javadoc-stable.yaml
   - restapidoc-stable.yaml
   - p2stable.yaml
   - resources.yaml
2. Let ArgoCD sync the `galasa-production` application in argocd.galasa.dev.