(To be updated in the projectmanagement repo also)

# How to release Galasa


## Introduction
With many repos making up the Galasa project and many different types of artifacts being produced, the build and release of Galasa has become a little complicated. These instructions detail the process of building, testing and releasing a version of Galasa and related components.

Galasa has been broken up into multiple components, and these components are only released if the component has changed. These components (and related repos) are:-

1. Galasa (wrapping, gradle, maven, framework, extensions, managers, obr, eclipse, isolated)
2. CLI (cli)

The Galasa component is always released, but the others are only cloned, built, tested and released if there are changes.


## Set up

1. Clone the 'automation' repository, main branch. All the yaml and scripts you will be using can be found in the releasePipeline folder.
2. Log into ArgoCD `argocd login --sso argocd.galasa.dev`
3. Log into both the internal cicsk8s and external ibmcloud Kubernetes clusters.
4. Ensure you have the latest galasabld program from https://development.galasa.dev/prod/binary/bld/ and it is on the path.
5. jq needs to be installed.
6. watch needs to be installed.
7. IBM Cloud CLI needs to be installed and logged in:
```
ibmcloud login --sso
ibmcloud cr region-set global
```

For each of the Kubernetes Tekton command, you can follow with tkn -n galasa-build pr logs -f --last to watch it's progress. Only move onto the next command once the previous is completed successfully.


## PRE-RELEASE PROCESS
It may be beneficial to complete a pre-release before starting a vx.xx.x release of Galasa. This is to ensure the main Galasa component builds successfully and to iron out any problems before the actual release, as there will be a freeze on delivering code during this time. 

**Do not check in any changes you make to files during this work item unless you are correcting a mistake - back out everything at the end**

1. Ensure you have complered Steps 1, 2 and 3 of the 'Set up' section of this README
2. Complete Steps 1, 2 and 3 of the 'Create branch and ArgoCD applications' section in the release process
   - Before doing Step 1, in 02-create-argocd-apps.sh, do a find and replace on the word 'release' and change to 'prerelease'. 
   - In Step 3, **ensure that the following parameters are set**: distBranch=prerelease, fromBranch=main
3. Complete Step 1 of 'Build the components' **ensuring that the following parameters are set**: toBranch=prerelease, revision=prerelease, refspec=refs/heads/prerelease:refs/heads/prerelease, imageTag=prerelease, appname=prerelease-maven-repos, jacocoEnabled=false, isMainOrRelease=true
4. Go to a maven artifact from each repository and check that the .asc files are present, which means the artifact has been signed. For example, https://development.galasa.dev/prerelease/maven-repo/wrapping/dev/galasa/com.auth0.jwt/<VERSION> should contain a file called com.auth0.jwt-<VERSION>.jar.asc.
5. If the .asc files aren't present, debug and diagnose why the artifacts have not been signed.


## RELEASE PROCESS

### Create branch and ArgoCD applications

1. 02-create-argocd-apps.sh - Create the Deployments and Tekton resources in Kubernetes.
2. Ensure Kubernetes context is set to the internal cicsk8s cluster.
3. Run `kubectl -n galasa-build create -f 10-clone-galasa.yaml` - Clone all the repos' main branches to release branches.


### Build the components

1. Run `kubectl -n galasa-build create -f 20-build-galasa.yaml` - Build the Galasa main component. **After each repo's build, go to its maven repository and check that the artifacts have been signed, there should be .asc files present**


### Regression test

1. Amend 28-regression-test-galasa.yaml - Set the correct version for this release, and the bootVersion for galasa-boot (check [here](https://development.galasa.dev/main/maven-repo/obr/dev/galasa/galasa-boot/) for current galasa-boot version)
2. Run `kubectl -n galasa-build create -f 28-regression-test-galasa.yaml` - Test Galasa.
3. If there are any failures from the regression testing - Amend 29-regression-reruns.yaml and pipelines/regression-reruns.yaml. Add the tests that failed, to run them again.
4. Run `kubectl -n galasa-build create -f 29-regression-reruns.yaml` - Retest the failing tests.
5. Repeat as required.

All the tests must pass before moving on.


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
8. 31-oss-sonatype-actions.md - Do the Sonatype actions detailed in this document.
9. 32-wait-maven.sh - Run the watch command to wait for the artifacts to reach Maven Central. The release will appear in the BOM metadata.
10. Wait until Maven Central is updated.
11. Amend 33-resources-image.yaml - Set the version.
12. Run `kubectl -n galasa-build create -f 33-resources-image.yaml` - Build the resources-image.
13. Amend 34-deploy-docker-galasa.sh - Set the version.
14. 34-deploy-docker-galasa.sh - Deploy the Container images to ICR.
15. Amend 35-deploy-docker-cli.sh - **Only if CLI being released** - Set the version.
16. 35-deploy-docker-cli.sh- **Only if CLI being released** - Deploy the CLI images to ICR.


### Update reference sites

1. 40-argocd-ibmcloud.md - Follow the instructions to update the IBM Cloud Galasa external sites.
2. 41-eclipse-marketplace.md - Follow the instructions to update the Eclipse Marketplace to advertise the latest Eclipse plugin.


### Tag release and deploy CLI

1. Amend 50-tag-galasa.yaml - Update the tag name, must be prefixed with lowercase v.
2. Run `kubectl -n galasa-build create -f 50-tag-galasa.yaml` - Tag the release on ALL repos.
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

1. Run `kubectl -n galasa-build create -f 90-delete-all-branches.yaml` - Delete the 'release' branch in the GitHub repositories and the images in Harbor tagged 'release'.
2. Go through the images in [IBM Cloud Container Registry](https://cloud.ibm.com/registry/images) and delete all images tagged 'release' that were built as part of this release (click three dots next to 'release' image and select Delete image). _This is a temporary step that we are working to automate._
3. 92-delete-argocd-apps.sh - Remove the ArgoCD applications, and therefore the Kubernetes resources.