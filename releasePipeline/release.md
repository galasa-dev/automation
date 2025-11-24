# RELEASE PROCESS

## Set up

1. Clone the 'automation' repository, main branch. All the yaml and scripts you will be using can be found in the releasePipeline folder.
2. Ensure the ArgoCD CLI is installed. The argocd cli can be downloaded [here]( https://argo-cd.readthedocs.io/en/stable/cli_installation/).
3. Log into ArgoCD `argocd login --sso argocd.galasa.dev --grpc-web`
4. Ensure GitHub CLI is istalled. It can be installed using the guide [here](https://github.com/cli/cli?tab=readme-ov-file#installation)
5. Authenticate github cli using `gh auth login --web`
6. You will need to log into both the internal cicsk8s and external ibmcloud Kubernetes clusters.
7. Ensure you have the latest galasabld program. It can be downloaded [here](https://development.galasa.dev/main/binary/bld/). Add it on the path.
8. jq needs to be installed. It can be downloaded [here](https://jqlang.github.io/jq/download/).
9. watch needs to be installed.
10. The ibmcloud CLI container registry service needs to be configured to the global region:

``` shell
ibmcloud cr region-set global
```

## Release steps

### Set up the ArgoCD apps and GitHub branches for the release

1. Ensure you have completed the [set up](#set-up) before continuing.
2. Run [02-create-argocd-apps.sh](./02-create-argocd-apps.sh). When prompted, choose the '`release`' option.
3. Run [03-repo-branches-delete.sh](./03-repo-branches-delete.sh). When prompted, choose the '`release`' option.  
4. Run [04-repo-branches-create.sh](./04-repo-branches-create.sh).  When prompted, choose the '`release`' option. **Note:** Creating this branch in the 'Helm' repository is all that is required to trigger the GitHub Actions workflow that packages and releases a new Tag and Release of the Helm charts.

### Check the Helm charts were released

1. Run [05-helm-charts.sh](./05-helm-charts.sh). When prompted, choose the '`release`' option. This script uses the GitHub API to check that all Helm charts that had changes in this release have a new Release and Tag object on GitHub.

### Build Galasa

1. Begin the build of Galasa by starting the Galasa mono repo release build. Run [10-build-galasa-mono-repo.sh](./10-build-galasa-mono-repo.sh). When prompted, choose the '`release`' option. This script uses the GitHub CLI to start the [Release Build Orchestrator](https://github.com/galasa-dev/galasa/actions/workflows/releases.yaml). You will have to monitor the workflow run and ensure it finishes successfully.
2. The build of the Isolated repository will be triggered automatically as part of the build chain, so monitor this build and make sure it finishes successfully. 
    - Watch the [Isolated Main build workflow](https://github.com/galasa-dev/isolated/actions/workflows/build.yaml) for the `release` ref back in GitHub
3. Now run the Web UI Main build. Run [11-build-webui.sh](./11-build-webui.sh). When prompted, choose the '`release`' option. This script uses the GitHub CLI to start the [Main build](https://github.com/galasa-dev/webui/actions/workflows/build.yaml). You will have to monitor the workflow run and ensure it finishes successfully.

### Check the built artifacts are signed
1. Run [20-check-artifacts-signed.sh](./20-check-artifacts-signed.sh). When prompted, choose the '`release`' option.
    - This will search and check that one artifact from each Galasa module (platform, wrapping, gradle, maven, framework, extensions, managers and obr) contains a file called *.jar.asc which shows the artifacts have been signed. If the .asc files aren't present, debug and diagnose why the artifacts have not been signed.

### Test the MVP zip

The steps below are to ensure the MVP zip works as described in the documentation.

**Note:** A [story](https://github.com/galasa-dev/projectmanagement/issues/2108) exists to automate this manual process for future releases.

1. Download the [MVP zip](https://development.galasa.dev/release/maven-repo/mvp/dev/galasa/galasa-isolated-mvp).
2. Unpack the zip and go to the folder in the command line.
3. Run `docker load -i isolated.tar` and confirm that the output is `Loaded image: ghcr.io/galasa-dev/galasa-mvp:main`. This is to ensure that the isolated.tar can be successfully untarred and loads a Docker image. 
4. If the last step was successful, run the provided Docker image by running `docker run -d -p 8080:80 --name galasa ghcr.io/galasa-dev/galasa-mvp:main`. Navigate to `localhost:8080` in a browser and confirm that the hosted version of the MVP zip appears. 
5. Follow the instructions on the [Exploring Galasa SimBank offline](https://galasa.dev/docs/running-simbank-tests/simbank-cli-offline) page of the documentation to ensure that a 3270 emulator can connect to the Simplatform application.
    - After starting the Simplatform application by running the `run-simplatform.sh` script, you can start your 3270 emulator pointing it to port 2023 of localhost by running `c3270 localhost -port 2023` (you will need the x3270 tool installed)

### MEND scan

1. Follow instructions from the internal [developer-docs wiki](https://github.ibm.com/galasa/developer-docs/wiki/how-to-mend-scan-galasa-mvp) on how to do this.

### Run the regression tests

#### Tests that run from GitHub Actions

Each of these scripts starts a GitHub Actions workflow. These test suites run tests from the GitHub Actions runner either locally in the runner, or they submit tests to run remotely on ecosystem1.

The script will give you the URL of the workflow run. You will have to monitor the workflow run in GitHub Actions and ensure it finishes successfully and all tests pass.

**These three steps can be done at the same time.**

1. Run [23-run-isolated-tests.sh](./23-run-isolated-tests.sh). This tests that the Simbank, Core and Artifact Managers work offline using just the Isolated/MVP zips.
2. Run [24-run-simbank-ivts.sh](./24-run-simbank-ivts.sh). This tests that the Simbank Managers work online.
3. Run [25-run-ecosystem1-ivts.sh](./25-run-ecosystem1-ivts.sh). This tests the Core, Artifact and HTTP Managers work online.

#### Tests that run from Tekton

Each of these scripts starts a Tekton pipeline on our internal cluster. This is because these tests require mainframe resource which we don't currently have available externally. These test suites run tests either locally on the Tekton runner, or submit tests to run from Tekton to prod1.

The script will give you the pipeline run name. You will have to monitor the pipeline run in Tekton and ensure it finishes successfully and all tests pass.

**These three steps should be done one after the other.**

1. Run [26-run-cicsts-isolated-tests.sh](./26-run-cicsts-isolated-tests.sh). This tests that the CICS, CEMT, CEDA and SDV Managers work offline using just the Isolated zip.
2. Run [27-run-prod1-ivts.sh](./27-run-prod1-ivts.sh). This tests that the CICS, CEMT, CEDA, SDV and z/OS Managers work online.
3. Run [28-run-prod1-integration-tests.sh](./28-run-prod1-integration-tests.sh).

Some tests may fail on the first run due to the lack of system resource availability. Rerunning the test should hopefully result in a pass. Make sure that external systems the tests connect to are active and healthy (for example, @hobbit1983's CICS Region).

For any tests which fail, run them again individually:

   b. Amend [29-regression-reruns.yaml](./29-regression-reruns.yaml) to supply the correct version and [regression-reruns.yaml](./argocd-synced/pipelines/regression-reruns.yaml). Add the tests that failed as shown in the example, to run them again.

   c. Run `kubectl apply -f argocd-synced/pipelines/regression-reruns.yaml` and `kubectl -n galasa-build create -f 29-regression-reruns.yaml`.

   d. Repeat as required.

**All the tests must pass before moving on.**

### Deploy the Galasa artifacts to Maven Central

1. Run the [30-central-publisher-portal.sh](./30-central-publisher-portal.sh) script which publishes a bundle of 'dev.galasa' artifacts to the Maven Central Publisher Portal with the Publisher API.
2. Log on to the Central Publisher Portal and publish the 'dev.galasa' artifacts by following the steps in [31-publish-to-maven-central.md](./31-publish-to-maven-central.md).
3. [32-wait-maven.sh](./32-wait-maven.sh) - Run the watch command to wait for the artifacts to reach Maven Central. The release will appear in the BOM metadata. Wait until Maven Central is updated. This could take around 20 to 40 minutes. Kill the terminal to exit this process.

### Deploy images to IBM Cloud Container Registry

1. Run [34-deploy-docker-galasa.sh](./34-deploy-docker-galasa.sh) - Deploy the Container images to ICR. It finds the version number we are releasing automatically. Re-tags the current images, and uploads the new ones. Takes over 20 mins.

### Create version tag from release branch

<!-- Will improve on this part -->
1. Ensure the 'release' branch on the automation repository is up to date with 'main' - it will be one commit behind as it won't have the updates to the galasa-production sites' image versions.
1. Ensure the 'release' branch on the galasa-docs-preview repository is up to date with 'main', in case any Main builds in Galasa ran and re-updated 'main'.
1. Publish the Galasa docs preview to the production site. Start the [Publish site to production workflow](https://github.com/galasa-dev/galasa-docs-preview/actions/workflows/publish.yaml) by clicking "Run workflow".
1. Ensure the 'release' branch on the galasa-docs repository is up to date with 'main'.
1. Run the [41-tag-github-repositories.sh](./41-tag-github-repositories.sh) - It figures out the galasa version, then creates a version tag from all the release branches in all the repositories. So we can later delete the release branches and the tags will still be there.

### Upload built artefacts as new Releases on GitHub

1. [42-upload-cli-release.md](./42-upload-cli-release.md) - Follow instructions to upload the CLI binaries to the repository under a new release.
1. [43-upload-isolated-release.md](./43-upload-isolated-release.md) - Follow instructions to upload the Isolated and MVP zips to the repository under a new release.

### Update Homebrew installed for the CLI

1. [44-update-homebrew.md](./44-update-homebrew.md) - Follow the manual steps in this file to make the new version of the CLI available for the homebrew installer.

### Bump to new version for development

1. [95-move-to-new-version.md](./95-move-to-new-version.md) - Follow the manual steps in this file to upgrade the development version of Galasa to the next one up.
2. Run the [set-version.sh](./set-version.sh) script which updates all CPS properties in the [`../infrastructure/cicsk8s/galasa-dev/cps-properties.yaml`](../infrastructure/cicsk8s/galasa-dev/cps-properties.yaml) file that contain the version that was just released to the new development version. Deliver the changes to the automation repository and the CPS properties will be applied automatically.

3. If the above fails and you need to update the CPS properties manually for some reason, run the [99-update-development-version.sh](./99-update-development-version.sh) script.

4. Update the CPS properties for the internal integrated tests using galasactl:

   a. framework.test.stream.internal-inttests.location

   b. framework.test.stream.internal-inttests.obr

5. Upgrade the version of the CLI we use for our regression testing to this released version. Retag the 'release' image of galasactl-ibm-x86_64 to 'stable' (regression testing uses galasactl-ibm-x86_64:stable):

``` shell
docker pull ghcr.io/galasa-dev/galasactl-ibm-x86_64:release
docker image tag ghcr.io/galasa-dev/galasactl-ibm-x86_64:release ghcr.io/galasa-dev/galasactl-ibm-x86_64:stable
docker image push ghcr.io/galasa-dev/galasactl-ibm-x86_64:stable
```

### Clean up

1. Run [03-repo-branches-delete.sh](./03-repo-branches-delete.sh) - Say you are doing a 'release' when it asks. That deletes the 'release' branch in the GitHub repositories.
2. (**Manual until we automate it with GitHub Actions**) Delete the images in GHCR tagged 'release':
   - obr-maven-artefacts
   - obr-generic
   - galasa-boot-embedded
   - galasa-ibm-boot-embedded
   - galasactl-x86_64
   - galasactl-ibm-x86_64
   - galasactl-executables
   - galasa-isolated
   - galasa-isolated-zip
   - galasa-mvp
   - galasa-mvp-zip
   - buildutils-executables
   - simplatform-maven-artefacts
3. Repeat steps 1 and 2 but with the branch 'pre-release'
4. [92-delete-argocd-apps.sh](./92-delete-argocd-apps.sh) - Remove the ArgoCD applications, and therefore the Kubernetes resources.
