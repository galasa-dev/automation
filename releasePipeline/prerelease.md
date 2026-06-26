# PRE-RELEASE PROCESS

It may be beneficial to complete a pre-release before starting a vx.xx.x release of Galasa. This is to ensure the main Galasa component builds successfully and to iron out any problems before the actual release, as there will be a freeze on delivering code during this time.

**Do not check in any changes you make to files during this work item unless you are correcting a mistake - back out everything at the end**

## Pre-release steps - Automated

1. Run the [Pre-release GitHub Actions workflow](https://github.com/galasa-dev/automation/actions/workflows/pre-release.yaml). If the process fails at any stage, you can continue by re-running the script that failed from the manual steps and finish using the [manual steps below](#pre-release-steps---manual).
2. When the Isolated pre-release build finishes, a Tekton pipeline to copy the MVP to an internal repo should start. Watch that pipeline and review the Mend scan results in the PR that gets opened. Then merge that PR.

## Pre-release steps - Manual

### Set up

1. Clone the 'automation' repository, main branch. All the yaml and scripts you will be using can be found in the releasePipeline folder.
2. Ensure the ArgoCD CLI is installed. The argocd cli can be downloaded [here]( https://argo-cd.readthedocs.io/en/stable/cli_installation/).
3. Log into ArgoCD `argocd login --sso argocd.galasa.dev --grpc-web`
4. Ensure GitHub CLI is istalled. It can be installed using the guide [here](https://github.com/cli/cli?tab=readme-ov-file#installation)
5. Authenticate github cli using `gh auth login`
6. Ensure the Tekton CLI is installed. You can download it [here](https://tekton.dev/docs/cli/).
7. Authenticate to the cicsk8s cluster using `cicsk8s sso`

### Steps

1. Ensure you have completed the [set up](#set-up) before continuing.
2. Run [02-create-argocd-apps.sh](./02-create-argocd-apps.sh). When prompted, choose the '`pre-release`' option.
3. Run [03-repo-branches-delete.sh](./03-repo-branches-delete.sh). When prompted, choose the '`pre-release`' option.
This script kicks off a pipeline to delete all branches called `prerelease` in all the github repositories, so we know they are clean.
4. Run [04-repo-branches-create.sh](./04-repo-branches-create.sh).  When prompted, choose the '`pre-release`' option.  This script creates
a new branch called `prerelease` in every github repo we need to build. **Note:** Creating this branch in the 'Helm' repository is all that is required to trigger the GitHub Actions workflow that packages and releases a new Tag and Release of the Helm charts. As this is a prerelease, they will need to be deleted after.
5. Run [05-helm-charts.sh](./05-helm-charts.sh). When prompted, choose the '`pre-release`' option. This script uses the GitHub API to check that all Helm charts that had changes in this release have a new Release and Tag object on GitHub.
6. Delete all Releases and Tags for the Helm charts that were just created by pushing to the `prerelease` branch.
    1. Delete all Releases that were created: [Releases](https://github.com/galasa-dev/helm/releases) - Next to a Release, click the Delete icon and 'Delete this release'.
    2. Delete all Tags that were created: [Tags](https://github.com/galasa-dev/helm/tags) - Next to a Tag, click the three dots, then 'Delete Tag' then 'Delete this Tag'.
7. Begin the build of Galasa by starting the Galasa mono repo release build. Run [10-build-galasa-mono-repo.sh](./10-build-galasa-mono-repo.sh). When prompted, choose the '`pre-release`' option. This script uses the GitHub CLI to start the [Release Build Orchestrator](https://github.com/galasa-dev/galasa/actions/workflows/releases.yaml). You will have to monitor the workflow run and ensure it finishes successfully.
8. The build of the Isolated repository will be triggered automatically as part of the build chain, so monitor this build and make sure it finishes successfully. 
    - Watch the [Isolated Main build workflow](https://github.com/galasa-dev/isolated/actions/workflows/build.yaml) for the `prerelease` ref back in GitHub
9. The build of the Web UI will also be triggered automatically as part of the build chain, so monitor this build and make sure it finishes successfully.
   - Watch the [Web UI Main build workflow](https://github.com/galasa-dev/webui/actions/workflows/build.yaml) for the `prerelease` ref back in GitHub
10. Run [20-check-artifacts-signed.sh](./20-check-artifacts-signed.sh). When prompted, choose the '`pre-release`' option.
    - This will search and check that one artifact from each Galasa module (platform, wrapping, gradle, maven, framework, extensions, managers and obr) contains a file called *.jar.asc which shows the artifacts have been signed. If the .asc files aren't present, debug and diagnose why the artifacts have not been signed.

## Test and scan the MVP

Ensure you have completed either the [automated](#pre-release-steps---automated) or [manual](#pre-release-steps---manual) pre-release steps first.

### MEND scan

1. Follow instructions from the internal [developer-docs wiki](https://github.ibm.com/galasa/developer-docs/wiki/how-to-mend-scan-galasa-mvp) on how to do this. **Note:** the bundles `dev.galasa.wrapping.com.auth0.jwt` and `dev.galasa.wrapping.kafka.clients` are not included in the MVP, therefore if vulnerabilities are found only in these bundles, they will not affect any IBM scans. However, they should still be remediated before starting the proper release if possible.

### Test the MVP

Run the automated MVP testing script to verify the MVP zip works as described in the documentation:

```bash
./test-mvp-zip.sh --prerelease
```

This script will:
1. Download the MVP zip from the prerelease repository
2. Extract and validate the isolated.tar Docker image
3. Load and run the Docker image, verifying the web interface at http://localhost:8080
4. Start the SimPlatform application
5. Run all SimBank tests using the extracted maven repository

If all tests pass, the MVP zip is ready for release.