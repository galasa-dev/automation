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
```
ibmcloud login --sso
ibmcloud cr region-set global
```

For each of the Kubernetes Tekton command, you can follow with tkn -n galasa-build pr logs -f --last to watch it's progress. Only move onto the next command once the previous is completed successfully.

## Release steps

1. Ensure you have completed the [set up](#set-up) before continuing.
2. Run [02-create-argocd-apps.sh](./02-create-argocd-apps.sh). When prompted, choose the '`release`' option.
3. Run [03-repo-branches-delete.sh](./03-repo-branches-delete.sh). When prompted, choose the '`release`' option.  
4. Run [04-repo-branches-create.sh](./04-repo-branches-create.sh).  When prompted, choose the '`release`' option. 

5. Run [20-build-all-code..sh](./20-build-all-code.sh). When prompted, choose the '`release`' option.
6. Run [28-run-regression-tests.sh](./28-run-regression-tests.sh). 
All the tests must pass before moving on.

For the ones which fail, run them individually :
  a. As currently some tests pass if run a second time due to the vaguaries of system resource availability. Also make sure @hobbit1983's VM image isn't down.
  b. If there are any failures from the regression testing - Amend 29-regression-reruns.yaml and pipelines/regression-reruns.yaml. Add the tests that failed, to run them again.
  c. Run `kubectl -n galasa-build create -f 29-regression-reruns.yaml` - Retest the failing tests.
  d. Repeat as required.


### Test the Eclipse plug-in and Simbank tests manually

1. Follow the [instructions](https://galasa.dev/docs/getting-started/installing-online) provided in our documentation to install the Eclipse plug-in, but instead of installing from https://p2.galasa.dev, install the release candidate from https://development.galasa.dev/release/maven-repo/p2/. Ensure you are using a [supporting version of Eclipse](https://galasa.dev/docs/getting-started) and Java 11.
2. Follow the [instructions](https://galasa.dev/docs/getting-started/simbank) provided to explore Simbank and run the supplied Simbank tests. Complete both sections 'Creating an example Galasa project using Maven' and 'Creating an example Galasa project using Gradle'. You will need to update your Galasa preferences (Eclipse > Settings > Galasa) and set the Remote Maven URI to https://development.galasa.dev/release/maven-repo/obr so Galasa can access the code to be released.


### Obtain release approval

1. Ask the Team and Product managers for release approval by:
   1. Finding the GitHub issue related to the release you are working on in the GHE repository cics/cics-ts-tracking.
   2. Checking off the tasks that are listed in the issue.
   3. Commenting, ensuring to tag the approvers (Roger and Simon) with a link to the regression test results for the 'release' branch on the Phoenix dashboard. Explain any failures that are due to external problems if necessary. Confirm manual installation of Eclipse plug-in and Simbank were successful.

Have a look at the GHE issues for previous releases for examples on how this has been done before. 

Once an approver has approved, you can move on.


### Deployment

<!-- Commenting out the steps below for now as they do not work. An item is open to fix this. Temporary steps to work around this below: -->
<!-- 1. Amend 30-deploy-maven-galasa.yaml and amend the version parameter to the release.
1. Run `kubectl -n galasa-build create -f 30-deploy-maven-galasa.yaml` - Deploy the maven artifacts to OSS Sonatype. -->
1. Pull the [galasa-obr-with-galasabld](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-obr-with-galasabld/artifacts-tab) image from Harbor using:

   ```
   docker pull harbor.galasa.dev/galasadev/galasa-obr-with-galasabld:release
   ```

2. Exec into the image so you can run commands from inside it by running:

   ```
   docker run -it --entrypoint /bin/sh harbor.galasa.dev/galasadev/galasa-obr-with-galasabld:release
   ```

3. When inside the image, run `cd htdocs/dev/galasa`
4. If the files maven-metadata.xml, maven-metadata.xml.md5 and maven-metadata.xml.sha1 are present, delete them, `rm maven-metadata.xml` etc.
5. Go to Vault and find the maven-creds secret, to use the username and password in the next step.
6. Navigate to the root directory in the image and then run the following command, to deploy all of the Maven artefacts we are releasing to the Nexus staging repository:

   ```
   galasabld maven deploy --repository https://s01.oss.sonatype.org/service/local/staging/deploy/maven2 --local /usr/local/apache2/htdocs --group dev.galasa --version <GALASA_VERSION_WE_ARE_RELEASING> --username <USERNAME> --password <PASSWORD>
   ```

7. `exit` the image.
<!-- End of temporary steps -->
8. 31-oss-sonatype-actions.md - Do the Sonatype actions detailed in this document, to check the maven artifacts are OK, and release them to maven central.
9. 32-wait-maven.sh - Run the watch command to wait for the artifacts to reach Maven Central. The release will appear in the BOM metadata. Wait until Maven Central is updated. Takes a while. 20 to 40-ish mins ? Kill the terminal to exit this process.
11. run the `33-build-resources-image.sh` script. It will find the version number we are releasing, and kick off the pipeline `release-*`. Wait for the pipeline to complete. Fairly quick. 5-ish mins.
14. run 34-deploy-docker-galasa.sh - Deploy the Container images to ICR. It finds the version number we are releasing automatically. Re-tags the current images, and uploads the new ones. Takes over 20 mins.


### Update reference sites

1. 40-argocd-ibmcloud.md - Follow the instructions to update the IBM Cloud Galasa external sites.
2. 41-eclipse-marketplace.md - Follow the instructions to update the Eclipse Marketplace to advertise the latest Eclipse plugin.


### Tag release and deploy CLI

1. Run the `50-tag-github-repositories.sh` - It figures out the galasa version, then creates a version tag from all the release branches in all the repositories. So we can later delete the release branches and the tags will still be there.
The pipeline it kicks off is called `tag-galasa-*`. Takes about a minute to complete. Check if finished OK on the tekton dashboard.
3. 52-deploy-cli-release.md - Follow instructions to deploy the CLI to the repo release.


### Bump to new version

1. 99-move-to-new-version.md - Follow the manual steps in this file to upgrade the development version of Galasa to the next one up.
2. Upgrade the version of Galasa to the new development version in the galasa-prod Ecosystem CPS properties: https://github.ibm.com/CICS/cicsts-galasa-config/blob/main/CPS.properties. Upgrade the galasaecosystem.runtime.version, galasaecosystem.isolated.mvp.zip and galasaecosystem.isolated.full.zip properties.
3. Upgrade the version of the CLI we use for our regression testing to this released version. Retag the 'release' image of galasa-cli-ibm-amd64 to 'stable' (regression testing uses galasa-cli-ibm-amd64:stable):
```
docker pull harbor.galasa.dev/galasadev/galasa-cli-ibm-amd64:release
docker image tag harbor.galasa.dev/galasadev/galasa-cli-ibm-amd64:release harbor.galasa.dev/galasadev/galasa-cli-ibm-amd64:stable
docker image push harbor.galasa.dev/galasadev/galasa-cli-ibm-amd64:stable
```


### Clean up

1. Run `03-repo-branches-delete.sh` - Say you are doing a 'release' when it asks. That Deletes the 'release' branch in the GitHub repositories and the images in Harbor tagged 'release'. Takes less than a minute.
2. Go through the images in [IBM Cloud Container Registry](https://cloud.ibm.com/registry/images) and delete all images tagged 'release' that were built as part of this release (click three dots next to 'release' image and select Delete image). _This is a temporary step that we are working to automate._
3. Repeat steps 1 and 2 but with the branch 'prerelease'
4. 92-delete-argocd-apps.sh - Remove the ArgoCD applications, and therefore the Kubernetes resources.

