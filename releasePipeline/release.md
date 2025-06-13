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
10. IBM Cloud CLI needs to be installed and logged in:

``` shell
ibmcloud login --sso
ibmcloud cr region-set global
```

For each of the Kubernetes Tekton command, you can follow with tkn -n galasa-build pr logs -f --last to watch it's progress. Only move onto the next command once the previous is completed successfully.

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
3. Run [28-run-prod1-integration-tests.sh](./28-run-prod1-integration-tests.sh). **These are the remaining inttests that have not yet been converted to an IVT.** All the tests must pass before moving on. For the ones which fail, run them individually:

   a. As currently some tests pass if run a second time due to the vaguaries of system resource availability. Also make sure @hobbit1983's VM image isn't down.

   b. If there are any failures from the regression testing, amend [29-regression-reruns.yaml](./29-regression-reruns.yaml) to supply the correct version and [regression-reruns.yaml](./argocd-synced/pipelines/regression-reruns.yaml). Add the tests that failed as shown in the example, to run them again.

   c. Run `kubectl apply -f argocd-synced/pipelines/regression-reruns.yaml` and `kubectl -n galasa-build create -f 29-regression-reruns.yaml` - Retest the failing tests.

   d. Repeat as required.

### Test the MVP zip contents against the galasa.dev documentation

1. **Note:** A [story](https://github.com/galasa-dev/projectmanagement/issues/2108) exists to automate this manual process for future releases. Test the [MVP zip](https://development.galasa.dev/release/maven-repo/mvp/dev/galasa/galasa-isolated-mvp) by working through the instructions on the Galasa website to do with using Galasa offline (although you will need to slightly adapt in some places as you are testing the MVP from the prerelease maven repo - these differences are documented below):
    - https://galasa.dev/docs/cli-command-reference/installing-offline
        - 1: The output of `docker load -i isolated.tar` should instead be `Loaded image: ghcr.io/galasa-dev/galasa-mvp:main`.
        - 2: Run the container by running `docker run -d -p 8080:80 --name galasa ghcr.io/galasa-dev/galasa-mvp:main` instead.
    - https://galasa.dev/docs/running-simbank-tests/simbank-cli-offline
        - After starting the Simplatform application by running the `run-simplatform.sh` script, you can start your 3270 emulator pointing it to port 2023 of localhost by running `c3270 localhost -port 2023` (you will need the x3270 tool installed)
    - https://galasa.dev/docs/running-simbank-tests/running-simbank-tests-cli-offline
        - To run the Simbank tests using the galasactl binary and using only the Maven artifacts provided within the zip, you can run the below commands from the top level of the zip:
            - `./galasactl/galasactl runs submit local --log - --obr mvn:dev.galasa/dev.galasa.simbank.obr/<VERSION>/obr --localMaven file:////Users/<YOURUSER>/Downloads/galasa-isolated-mvp-<VERSION>/maven --class dev.galasa.simbank.tests/dev.galasa.simbank.tests.SimBankIVT`
            - `./galasactl/galasactl runs submit local --log - --obr mvn:dev.galasa/dev.galasa.simbank.obr/<VERSION>/obr --localMaven file:////Users/<YOURUSER>/Downloads/galasa-isolated-mvp-<VERSION>/maven --class dev.galasa.simbank.tests/dev.galasa.simbank.tests.BasicAccountCreditTest`
            - `./galasactl/galasactl runs submit local --log - --obr mvn:dev.galasa/dev.galasa.simbank.obr/<VERSION>/obr --localMaven file:////Users/<YOURUSER>/Downloads/galasa-isolated-mvp-<VERSION>/maven --class dev.galasa.simbank.tests/dev.galasa.simbank.tests.ProvisionedAccountCreditTests`
            - `./galasactl/galasactl runs submit local --log - --obr mvn:dev.galasa/dev.galasa.simbank.obr/<VERSION>/obr --localMaven file:////Users/<YOURUSER>/Downloads/galasa-isolated-mvp-<VERSION>/maven --class dev.galasa.simbank.tests/dev.galasa.simbank.tests.BatchAccountsOpenTest`

### MEND scan (if releasing Distribution for Galasa)

1. Follow instructions from the internal [developer-docs](https://pages.github.ibm.com/galasa/developer-docs/300-process/dfg-build-process/) on how to do this.

### Obtain release approval (if releasing Distribution for Galasa)

1. Ask the Team and Product managers for release approval by:
   1. Finding the GitHub issue related to the release you are working on in the GHE repository cics/cics-ts-tracking.
   2. Checking off the tasks that are listed in the issue.
   3. Commenting, ensuring to tag the approvers (Roger and Simon) with a link to the regression test results for the 'release' branch on the Phoenix dashboard. Explain any failures that are due to external problems if necessary.

Have a look at the GHE issues for previous releases for examples on how this has been done before.

Once an approver has approved, you can move on.

### Deploy the Galasa artifacts to Maven Central

1. Run the [30-central-publisher-portal.sh](./30-central-publisher-portal.sh) script which publishes a bundle of 'dev.galasa' artifacts to the Maven Central Publisher Portal with the Publisher API.
1. Once the bundle reaches the portal, various validation checks will be done on the bundle. If all validation checks pass, you will have to log into the Central Publisher Portal and publish the bundle manually. Complete the steps detailed in [31-publish-to-maven-central.md](./31-publish-to-maven-central.md) to publish the bundle to Maven Central.
3. [32-wait-maven.sh](./32-wait-maven.sh) - Run the watch command to wait for the artifacts to reach Maven Central. The release will appear in the BOM metadata. Wait until Maven Central is updated. Takes a while. 20 to 40-ish mins. Kill the terminal to exit this process.

### Deploy resources.galasa.dev

1. Run the [33-build-resources-image.sh](./33-build-resources-image.sh) script. It will find the version number we are releasing, and kick off the pipeline `release-*`. Wait for the pipeline to complete. Fairly quick. 5-ish mins.

### Deploy images to IBM Cloud Container Registry

1. Run [34-deploy-docker-galasa.sh](./34-deploy-docker-galasa.sh) - Deploy the Container images to ICR. It finds the version number we are releasing automatically. Re-tags the current images, and uploads the new ones. Takes over 20 mins.

### Update external sites

1. [40-production-sites.md](./40-production-sites.md) - Follow the instructions to update the IBM Cloud Galasa external sites.

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
2. In the file `../infrastructure/cicsk8s/galasa-dev/cps-properties.yaml` update all CPS properties that contain the just released version to contain the new development version number. Deliver the changes to the automation repository and the CPS properties will be applied automatically.

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

1. Run [03-repo-branches-delete.sh](./03-repo-branches-delete.sh) - Say you are doing a 'release' when it asks. That Deletes the 'release' branch in the GitHub repositories.
2. (**Manual until we automate it with GitHub Actions**) Delete the images in GHCR tagged 'release':
   - obr-maven-artefacts
   - obr-generic
   - galasa-boot-embedded
   - galasa-ibm-boot-embedded
   - javadoc-maven-artefacts
   - javadoc-site
   - galasactl-x86_64
   - galasactl-ibm-x86_64
   - galasactl-executables
2. Go through the images in [IBM Cloud Container Registry](https://cloud.ibm.com/registry/images) and delete all images tagged 'release' that were built as part of this release (click three dots next to 'release' image and select Delete image). _This is a temporary step that we are working to automate._
3. Repeat steps 1, 2 and 3 but with the branch 'pre-release'
4. 92-delete-argocd-apps.sh - Remove the ArgoCD applications, and therefore the Kubernetes resources.
