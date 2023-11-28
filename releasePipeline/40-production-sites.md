# Update the Galasa production sites

1. Go to the definitions for the production sites in ../infrastructure/galasa-plan-b-lon02/galasa-production/galasa-production.
2. Update the images with the correct version for this release in the following files:
   - javadoc-stable.yaml
   - restapidoc-stable.yaml
   - p2stable.yaml
   - resources.yaml
3. Let ArgoCD sync the `galasa-production` application in argocd.galasa.dev.