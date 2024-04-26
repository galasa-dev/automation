# RELEASE PROCESS

## Set up

1. Clone the 'automation' repository, main branch. All the yaml and scripts you will be using can be found in the releasePipeline folder.
2. Ensure argocd is installed. The argocd cli can be downloaded [here]( https://argo-cd.readthedocs.io/en/stable/cli_installation/).
3. Log into ArgoCD `argocd login --sso argocd.galasa.dev`
4. You will need to log into both the internal cicsk8s and external ibmcloud Kubernetes clusters.
5. Ensure you have the latest galasabld program. It can be downloaded [here](https://development.galasa.dev/main/binary/bld/). Add it on the path.
6. jq needs to be installed. It can be downloaded [here](https://jqlang.github.io/jq/download/).
7. watch needs to be installed.
8. IBM Cloud CLI needs to be installed and logged in:

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

### Build and test the Galasa core components

1. Run [20-build-all-code.sh](./20-build-all-code.sh). When prompted, choose the '`release`' option.
2. Run [21-build-webui.sh](./21-build-webui.sh). When prompted, choose the '`release`' option.
3. Run [28-run-regression-tests.sh](./28-run-regression-tests.sh). All the tests must pass before moving on. For the ones which fail, run them individually:

   a. As currently some tests pass if run a second time due to the vaguaries of system resource availability. Also make sure @hobbit1983's VM image isn't down.

   b. If there are any failures from the regression testing - Amend 29-regression-reruns.yaml to supply the correct version and argocd-synced/pipelines/regression-reruns.yaml. Add the tests that failed as shown in the example, to run them again.

   c. Run `kubectl apply -f argocd-synced/pipelines/regression-reruns.yaml` and `kubectl -n galasa-build create -f 29-regression-reruns.yaml` - Retest the failing tests.

   d. Repeat as required.

### Obtain release approval (if releasing Distribution for Galasa)

1. Ask the Team and Product managers for release approval by:
   1. Finding the GitHub issue related to the release you are working on in the GHE repository cics/cics-ts-tracking.
   2. Checking off the tasks that are listed in the issue.
   3. Commenting, ensuring to tag the approvers (Roger and Simon) with a link to the regression test results for the 'release' branch on the Phoenix dashboard. Explain any failures that are due to external problems if necessary.

Have a look at the GHE issues for previous releases for examples on how this has been done before.

Once an approver has approved, you can move on.

### Deploy the Galasa artifacts to Maven Central

1. Run the 30-deploy-maven-galasa.sh script - Deploys the maven artifacts to OSS Sonatype.

   <!-- Temporary steps if there are issues with the 30-deploy-maven-galasa.sh script: -->
   <!--  1. Pull the [galasa-obr-with-galasabld](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-obr-with-galasabld/artifacts-tab) image from Harbor using:

      ```shell
      docker pull harbor.galasa.dev/galasadev/galasa-obr-with-galasabld:release
      ```

   2. Exec into the image so you can run commands from inside it by running:

      ```shell
      docker run -it --entrypoint /bin/sh harbor.galasa.dev/galasadev/galasa-obr-with-galasabld:release
      ```

   3. When inside the image, run:

      ```shell
      cd htdocs/dev/galasa
      ```

   4. If the files maven-metadata.xml, maven-metadata.xml.md5 and maven-metadata.xml.sha1 are present, delete them:

      ```shell
      rm maven-metadata.xml
      rm maven-metadata.xml.md5
      rm maven-metadata.xml.sha1
      ```

   5. Go to the IBM Cloud Secrets Manager and find the sonatype-credentials secret, to use the username and password in the next step.
   6. Navigate to the root directory in the image and then run the following command, to deploy all of the Maven artefacts we are releasing to the staging repository:

      ```shell
      galasabld maven deploy --repository https://s01.oss.sonatype.org/service/local/staging/deploy/maven2 --local /usr/local/apache2/htdocs --group dev.galasa --version <GALASA_VERSION_WE_ARE_RELEASING> --username <USERNAME> --password <PASSWORD>
      ```

   7. `exit` the image. -->
   <!-- End of temporary steps -->
2. 31-oss-sonatype-actions.md - Do the Sonatype actions detailed in this document, to check the maven artifacts are OK, and release them to maven central.
3. 32-wait-maven.sh - Run the watch command to wait for the artifacts to reach Maven Central. The release will appear in the BOM metadata. Wait until Maven Central is updated. Takes a while. 20 to 40-ish mins ? Kill the terminal to exit this process.

### Deploy resources.galasa.dev

1. Run the `33-build-resources-image.sh` script. It will find the version number we are releasing, and kick off the pipeline `release-*`. Wait for the pipeline to complete. Fairly quick. 5-ish mins.

### Deploy images to IBM Cloud Container Registry

1. run 34-deploy-docker-galasa.sh - Deploy the Container images to ICR. It finds the version number we are releasing automatically. Re-tags the current images, and uploads the new ones. Takes over 20 mins.

### Update external sites

1. 40-argocd-ibmcloud.md - Follow the instructions to update the IBM Cloud Galasa external sites.

### Tag release and deploy CLI

1. Run the `50-tag-github-repositories.sh` - It figures out the galasa version, then creates a version tag from all the release branches in all the repositories. So we can later delete the release branches and the tags will still be there.
The pipeline it kicks off is called `tag-galasa-*`. Takes about a minute to complete. Check if finished OK on the tekton dashboard.
2. 52-deploy-cli-release.md - Follow instructions to deploy the CLI to the repo release.

### Bump to new version for development

1. 99-move-to-new-version.md - Follow the manual steps in this file to upgrade the development version of Galasa to the next one up.
2. Upgrade the values of the CPS properties by running the `set-version.sh` script.
3. Upgrade the version of the CLI we use for our regression testing to this released version. Retag the 'release' image of galasa-cli-ibm-amd64 to 'stable' (regression testing uses galasa-cli-ibm-amd64:stable):

``` shell
docker pull harbor.galasa.dev/galasadev/galasa-cli-ibm-amd64:release
docker image tag harbor.galasa.dev/galasadev/galasa-cli-ibm-amd64:release harbor.galasa.dev/galasadev/galasa-cli-ibm-amd64:stable
docker image push harbor.galasa.dev/galasadev/galasa-cli-ibm-amd64:stable
```

### Clean up

1. Run `03-repo-branches-delete.sh` - Say you are doing a 'release' when it asks. That Deletes the 'release' branch in the GitHub repositories and the images in Harbor tagged 'release'. Takes less than a minute.
2. Go through the images in [IBM Cloud Container Registry](https://cloud.ibm.com/registry/images) and delete all images tagged 'release' that were built as part of this release (click three dots next to 'release' image and select Delete image). _This is a temporary step that we are working to automate._
3. Repeat steps 1 and 2 but with the branch 'prerelease'
4. 92-delete-argocd-apps.sh - Remove the ArgoCD applications, and therefore the Kubernetes resources.
