# PRE-RELEASE PROCESS
It may be beneficial to complete a pre-release before starting a vx.xx.x release of Galasa. This is to ensure the main Galasa component builds successfully and to iron out any problems before the actual release, as there will be a freeze on delivering code during this time. 

**Do not check in any changes you make to files during this work item unless you are correcting a mistake - back out everything at the end**

## Set up

1. Clone the 'automation' repository, main branch. All the yaml and scripts you will be using can be found in the releasePipeline folder.
2. Ensure the ArgoCD CLI is installed. The argocd cli can be downloaded [here]( https://argo-cd.readthedocs.io/en/stable/cli_installation/).
3. Log into ArgoCD `argocd login --sso argocd.galasa.dev`
4. Ensure the Tekton CLI is installed. You can download it [here](https://tekton.dev/docs/cli/).


## Pre-release steps

1. Ensure you have completed the [set up](#set-up) before continuing.
2. Run [02-create-argocd-apps.sh](./02-create-argocd-apps.sh). When prompted, choose the '`pre-release`' option.
3. Run [03-repo-branches-delete.sh](./03-repo-branches-delete.sh). When prompted, choose the '`pre-release`' option. 
This script kicks off a pipeline to delete all branches called `prerelease` in all the github repositories, so we know they are clean.
4. Run [04-repo-branches-create.sh](./04-repo-branches-create.sh).  When prompted, choose the '`pre-release`' option.  This script creates
a new branch called `prerelease` in every github repo we need to build.
5. Run [20-build-all-code..sh](./20-build-all-code.sh). When prompted, choose the '`pre-release`' option.
6. Run [25-check-artifacts-signed.sh](./25-check-artifacts-signed.sh). When prompted, choose the '`pre-release`' option. 
    - Each maven artifact should contain a file called com.auth0.jwt-<*VERSION*>.jar.asc. If the .asc files aren't present, debug and diagnose why the artifacts have not been signed.

7. Send the [mvp image](https://development.galasa.dev/prerelease/maven-repo/mvp/dev/galasa/galasa-isolated-mvp) to Will Yates to perform the MEND scan to check for any vulnerabilities before moving onto the release process.