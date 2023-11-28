# branch-maven-repos

This helm chart is used by 3 argocd projects on the publish cluster:

- codecov-maven-repos
- integration-maven-repos
- main-maven-repos

Each argocd project uses a different values.yaml file.

The values files are found [here](./values-used-by-different-argo-apps/)

Use the [`argo-app-create.sh`](../../argo-app-create.sh) script to use these values files.