# Update the Galasa production sites

1. Go to the definitions for the production sites in ../infrastructure/galasa-plan-b-lon02/galasa-production/galasa-production.
2. Update the images with the correct version for this release in the following files:
   - restapidoc-stable.yaml
3. Create a new branch with the changes and raise a PR to merge into the `main` branch.
4. Let ArgoCD sync the `galasa-production` application in argocd.galasa.dev.
