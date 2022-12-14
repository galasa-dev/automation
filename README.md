# Galasa Automation Repository

This repository is the single location for all the automation and CI/CD that occurs in Galasa. 

Find out more about:
1. [Build-images](#build-images) - custom images required for the build process
1. [Dockerfiles](#dockerfiles) - the organised Dockerfiles for all the images built for galasa
1. [Infrastructure](#infrastructure) - the Galasa infrastructure as code, including the Kubernetes set-up
1. [Pipelines](#pipelines) - the components used in our Tekton build pipelines, such as Pipelines and Tasks


# Build-images

This directory holds the Go code for custom build images.

github-status:

This image provides the status of a pull request build - whether it passed or failed - and updates the pull request on GitHub with this status.

github-verify:

This image is used to verify that a user who opens a pull request into a repository, is an approved code-committer or code-admin, before proceeding with a build.

github-monitor:

This image is used to monitor the galasa-dev organisation-wide webhook for any new deliveries, every 2 minutes. It will then trigger the appropriate EventListener for each delivery to then trigger the corresponding build pipeline.


# Dockerfiles

This directory is the single location for all Dockerfiles needed to build the images Galasa needs.

| Category | Dockerfiles |
|----------|-------------|
| Custom images (If there is not be a Docker official image that allows us to use a tool, we have created custom images to enable this. The Dockerfiles for all of the custom images are in the _common_ directory) | argocd, gitcli, gpg, kubectl, tkn | 
| Go programs | ghstatus, ghverify, github-monitor |
| Base image (All other images are built on top of this. Used to enable use of the Apache HTTP Server) | base |
| Galasa core repositories | wrapping, gradle, maven, framework, extensions, managers, obr |
| Galasa runtime images | obrGeneric, bootEmbedded, ibmBootEmbedded | 
| Galasa Eclipse plug-in | eclipse, eclipse-p2 |
| Galasa Isolated build | isolated, isolatedZip |
| Galasa Integrated tests | inttests |
| Galasa CLI tools | galasabld, galasactl | 
| Galasa Javadoc | javadoc-maven-repo, javadoc-site |
| Galasa Simplatform | simplatform, simplatform-amd64, simbank webapp |


# Infrastructure

Galasa's infrastructure is currently spread across two Kubernetes clusters - an internal cluster and an external cluster. 

cicsk8s:
* All Tekton build pipelines are run on the internal cluster.
* The Argo CD instance which controls all resources for the pipelines (Pipelines, Tasks, etc) is hosted on the internal cluster.

ibmcloud-galasadev-cluster: 
* All Deployments, Services and Ingresses which make up our Maven artifact repositories are hosted on the external cluster.
* The [Argo CD](argocd.galasa.dev) instance which controls the above resources is hosted on the external cluster.
* Our image registry [Harbor](harbor.galasa.dev) is hosted on the external cluster.


# Pipelines

## Event Listeners

A webhook is set up for the galasa-dev organisation on GitHub. Every 2-minutes, the github-monitor checks for new events and triggers one of the three EventListeners where necessary.

_Currently, payload validation has been turned off with an annotation in the metadata for these EventListeners. This is because the github-monitor currently cannot validate the payloads from GitHub. This will be turned on in the future once the github-monitor can validate payloads from GitHub._

### github-pr-builder-listener

This EventListener is triggered via webhook when a pull request is opened in a repository.

If a pull request is opened by someone who is not part of an approved group (code admins or code committers), building of the PR will be blocked, until a code admin has commented on the PR 'Approved for building'. Otherwise, this will trigger a PR build.

### github-pr-review-builder-listener

This EventListener is triggered via webhook when a code-admin submits the 'Approved for building' comment on a pull request that was blocked from building. This will then trigger a PR build.

### github-main-builder-listener

This EventListener is triggered via webhook when code is pushed into the main branch of a repository, and triggers a main build of that repository.


## Pipelines

Galasa's architecture means that components are built on top of each other, using artifacts from the previous components. The diagram below shows the links between components, starting from Wrapping.

In the pipelines, you will see that during some of the Maven or Gradle builds, the Maven source is pointed at the Maven artifact repository of the previous component. So, Framework's Gradle build has the build argument _-PsourceMaven=https://development.galasa.dev/main/maven-repo/maven_ so it can use artifacts from Maven's build.

You will also notice that the Dockerfiles for some components are FROM the previous component.

![](./docs-images/repo-links.png)

_For more information about the Tasks used in the Pipelines, see the **Tasks** section of this README._

### PR builds (_pr-REPO-NAME_)

PR builds are triggered when a pull request has been opened in one of Galasa's GitHub repositories. The build is done to check that all of the source code submitted in that PR compiles, builds, and that the unit tests pass. 

To ensure that code from an unknown source is not built, PR builds start by verifying if the author of the PR is in an approved group. If they are, the pipeline will proceed, but, if not, the pipeline will stop and an approved user will need to approve the PR for building.

A docker image of the component is also built and pushed to [harbor](harbor.galasa.dev), and the image is tagged with the latest commit sha in the PR.

Finally, the pipeline returns the status of the build, Success, Failure or Error, to the pull request on GitHub.

### Main builds (_branch-REPO-NAME_)

Main builds are triggered when code has been merged or pushed into the main branch on one of Galasa's GitHub repositories. The build checks that the source code compiles, builds, and that the unit tests pass. It also builds a docker image of the repository and pushes it to harbor, this time with the tag "main".

Any deployments that host images built as part of this pipeline are also recycled so that the changes are reflected.

Each Main build also triggers the Main build of the next component in the chain.

As well as being triggered from pushes/merges into main, a Main build can occur when a full Branch build of Galasa is started. _More information on this to come._

### Branch builds (_branch-REPO-NAME_)

Branch builds are triggered manually to build a branch's version of Galasa code and the corresponding images tagged with the branch name, such as galasa-obr:_{BRANCHNAME}_. These images can then be used to deploy a branch's version of the Maven artifact repositories, such as development.galasa.dev/_{BRANCHNAME}_/maven-repo/obr. 

Branch builds do exactly the same thing as Main builds, just for other branches. This is useful as you may want to conduct regression testing against your branch before you merge your changes into the main branch, and you must provide Galasa's regression tests with an OBR Maven repository like the endpoint above, so will need to build your branch and create the Deployments for an OBR repo.

To build changes across multiple GitHub repositories at the same time, the changes must be on the same branch.

**How to do a branch build:**

This example is for a branch build for branch iss001 that contains changes to Framework and Managers (Framework is the first pipeline).

1. Before starting a branch build, you must set up an app on [Argo CD](argocd.galasa.dev) to control your Deployments.
![](./docs-images/create-argocd-app.png)
2. As Framework is the first pipeline in the chain that has changes to be built, you must set up Deployments for Framework and all other repos that come after it, so Framework, Extensions, Managers and OBR. You do this by overriding the values from values.yaml to _REPO_.deploy = true, _REPO_.branch = _BRANCH_ and _REPO_.imageTag = _BRANCH_.
![](./docs-images/edit-values.png)
3. The app and all of its resources will show as 'Unhealthy' at first, as the Docker images tagged with your branch name do not exist yet, as they have not been built.
4. Manually start the first pipeline by executing a tkn command, passing in parameters. This command must be ran inside the automation directory, as it references the podTemplate and volumeClaimTemplate for the workspace. If you don't want to run this command inside the automation directory, change the paths to the templates. For our example, running inside the automation directory this would be the command:
```
tkn pipeline start branch-framework -n galasa-build \
--prefix-name trigger-framework-branch \
--workspace name=git-workspace,volumeClaimTemplateFile=pipelines/templates/git-workspace-template.yaml \
--pod-template pipelines/templates/pod-template.yaml --serviceaccount galasa-build-bot \ 
--param fromBranch=main \
--param toBranch=iss001 \
--param refspec=refs/heads/iss001:refs/heads/iss001 \
--param imageTag=iss001 \
--param appname=iss001-maven-repo
```
5. The first pipeline should start, and then will trigger the following pipeline in the chain by running a similar tkn command in a task at the end of the pipeline.
6. After the OBR pipeline has successfully ran, go to your app on Argo CD and 'Sync' your resources.
7. Your branch build is complete.
8. Remember to delete your app from Argo CD and clear up your branch's images when you are done with your branch.


**Automation**

These pipelines build all of the images used for Galasa's build pipelines, which are stored in the [Automation repository](https://github.com/galasa-dev/automation).

pr-automation:
1. git-verify
1. clone-automation
1. get-commit
1. go-build-ghverify
1. go-build-ghstatus
1. build-gpg-image
1. build-kubectl-image
1. build-gitcli-image
1. build-tkn-image
1. git-status

branch-automation:
1. clone-automation
1. get-commit
1. go-build-ghverify
1. build-ghverify-image
1. go-build-ghstatus
1. build-ghstatus-image
1. go-build-ghmonitor
1. build-ghmonitor-image
1. build-gpg-image
1. build-kubectl-image
1. build-gitcli-image
1. build-tkn-image

Docker images built by these pipelines are pushed [here](https://harbor.galasa.dev/harbor/projects/5/repositories).


**Buildutils**

These pipelines build the binaries for the galasabld CLI tool, the code for which is in the [Buildutils repository](https://github.com/galasa-dev/buildutils).

pr-buildutils:
1. git-verify
1. clone-automation
1. clone-buildutils
1. make
1. build-galasabld-image
1. git-status

branch-buildutils:
1. clone-automation
1. clone-buildutils
1. make
1. build-galasabld-image

The Docker image for the galasabld CLI is pushed [here](https://harbor.galasa.dev/harbor/projects/3/repositories/galasabld/artifacts-tab).


**CLI**

These pipelines build the binaries for the galasactl CLI tool, the code for which is in the [CLI repository](https://github.com/galasa-dev/cli).

pr-cli:
1. git-verify
1. clone-automation
1. clone-framework
1. clone-cli
1. generate-api
1. clear-mod
1. clear-sum
1. update-version
1. get-commit
1. galasactl-make
1. docker-build-cli
1. docker-build-cli-ibm
1. docker-build-cli-binary
1. git-status

branch-cli:
1. clone-automation
1. clone-framework
1. clone-cli
1. check-branch
1. generate-api
1. clear-mod
1. clear-sum
1. update-version
1. get-commit
1. galasactl-make
1. docker-build-cli
1. docker-build-cli-ibm
1. docker-build-cli-binary
1. recycle-cli-binary
1. wait-cli-binary

The Docker image for the galasactl CLI is pushed [here](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-cli-amd64/artifacts-tab).

The Docker image conatining the galasactl CLI binaries is pushed [here](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-cli-binary-downloadables/artifacts-tab).

The CLI binaries are downloadable from [here](https://development.galasa.dev/main/binary/cli).

**Eclipse**

These pipelines build the [Galasa Eclipse plug-in](https://github.com/galasa-dev/eclipse).

pr-eclipse:
1. git-verify
1. clone-automation
1. clone-eclipse
1. get-commit
1. maven-gpg
1. maven-build-eclipse
1. docker-build-eclipse
1. docker-build-eclipse-p2
1. git-status

branch-eclipse:
1. clone-automation
1. clone-eclipse
1. get-commit
1. maven-gpg
1. branch-maven-build-eclipse
1. branch-docker-build-eclipse
1. branch-docker-build-eclipse-p2
1. recycle-deployment
1. wait-deployment

The Docker image for the Maven repo for Eclipse is pushed [here](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-eclipse/artifacts-tab) and the image for the Eclipse P2 site is [here](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-eclipse-p2/artifacts-tab).

The Eclipse Maven repository is [here](https://development.galasa.dev/main/maven-repo/eclipse).


**Extensions**

These pipelines build the [Galasa Extensions](https://github.com/galasa-dev/extensions).

pr-extensions:
1. git-verify
1. clone-automation
1. clone-extensions
1. get-commit
1. gradle-build-extensions
1. docker-build-extensions
1. git-status

branch-extensions:
1. clone-automation
1. clone-extensions
1. get-commit
1. branch-gradle-build-extensions
1. branch-docker-build-extensions
1. recycle-deployment
1. wait-deployment
1. trigger-managers

The Docker image for the Extensions Maven repo is [here](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-extensions/artifacts-tab).

The Extensions Maven repository is [here](https://development.galasa.dev/main/maven-repo/extensions).


**Framework**

These pipelines build the [Galasa Framework](https://github.com/galasa-dev/framework)

pr-framework:
1. git-verify
1. clone-automation
1. clone-framework
1. get-commit
1. gradle-build-framework
1. docker-build-framework
1. git-status

branch-framework:
1. clone-automation
1. clone-framework
1. get-commit
1. branch-gradle-build-framework
1. branch-docker-build-framework
1. recycle-deployment
1. wait-deployment
1. trigger-extensions

The Docker image for the Framework Maven repo is [here](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-framework/artifacts-tab).

The Framework Maven repository is [here](https://development.galasa.dev/main/maven-repo/framework).


**Gradle**

These pipelines build the [Galasa Gradle plug-in](https://github.com/galasa-dev/gradle)

pr-gradle:
1. git-verify
1. clone-automation
1. clone-gradle
1. get-commit
1. gradle-build-gradle
1. docker-build-gradle
1. git-status

branch-gradle:
1. clone-automation
1. clone-gradle
1. get-commit
1. branch-gradle-build-gradle
1. branch-docker-build-gradle
1. recycle-deployment
1. wait-deployment
1. trigger-maven

The Docker image for the Gradle Maven repo is [here](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-gradle/artifacts-tab).

The Gradle Maven repository is [here](https://development.galasa.dev/main/maven-repo/gradle).


**Integrated tests**

These pipelines build the [Galasa Integrated tests](https://github.com/galasa-dev/integratedtests)

pr-integratedtests:
1. git-verify
1. clone-automation
1. clone-inttests
1. get-commit
1. branch-gradle-build-inttests
1. branch-maven-build-inttests
1. branch-docker-build-inttests
1. git-status

branch-integratedtests:
1. clone-automation
1. clone-inttests
1. check-branch
1. get-commit
1. branch-gradle-build-inttests
1. branch-maven-build-inttests
1. branch-docker-build-inttests
1. recycle-deployment
1. wait-deployment

The Docker image for the Integrated tests Maven repo is [here](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-inttests/artifacts-tab).

The Integrated tests Maven repository is [here](https://development.galasa.dev/main/maven-repo/inttests).

**Isolated**

These pipelines build the isolated and mvp images which are used to install Galasa offline. [Galasa Isolated](https://github.com/galasa-dev/isolated) 

pr-isolated:
1. git-verify
1. clone-automation
1. clone-obr
1. clone-framework
1. clone-extensions
1. clone-isolated
1. generate-pom
1. maven-build-isolated1
1. maven-build-isolated2
1. maven-build-isolated3
1. maven-build-isolated4
1. maven-build-isolated5
1. maven-build-isolated6
1. maven-build-javadoc
1. maven-build-docs
1. copy-text-files
1. docker-build-isolated
1. docker-build-tar-isolated
1. maven-build-isolated-zip
1. docker-build-isolated-zip
1. generate-pom-mvp
1. maven-build-mvp1
1. maven-build-mvp2
1. maven-build-mvp3
1. maven-build-mvp4
1. maven-build-mvp5
1. maven-build-mvp6
1. maven-build-javadoc-mvp
1. maven-build-docs-mvp
1. copy-text-files-mvp
1. docker-build-mvp
1. docker-build-tar-mvp
1. maven-build-mvp-zip
1. docker-build-mvp-zip
1. git-status

branch-isolated:
1. clone-automation
1. clone-obr
1. clone-framework
1. clone-extensions
1. clone-isolated
1. check-branch
1. generate-pom
1. maven-build-isolated1
1. maven-build-isolated2
1. maven-build-isolated3
1. maven-build-isolated4
1. maven-build-isolated5
1. maven-build-isolated6
1. maven-build-javadoc
1. maven-build-docs
1. copy-text-files
1. docker-build-isolated
1. docker-build-tar-isolated
1. maven-build-isolated-zip
1. docker-build-isolated-zip
1. recylce-deployment
1. wait-deployment
1. generate-pom-mvp
1. maven-build-mvp1
1. maven-build-mvp2
1. maven-build-mvp3
1. maven-build-mvp4
1. maven-build-mvp5
1. maven-build-mvp6
1. maven-build-javadoc-mvp
1. maven-build-docs-mvp
1. copy-text-files-mvp
1. docker-build-mvp
1. docker-build-tar-mvp
1. maven-build-mvp-zip
1. docker-build-mvp-zip
1. recylce-deployment-mvp
1. wait-deployment-mvp

The Docker image for the isolated build is [here](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-isolated/artifacts-tab).

The Docker image for isolated.tar is [here](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-distribution/artifacts-tab). This image may be used if you want to host Galasa on an internal server to be accessed by other users. 

The isolated zip file can be downloaded from [here](https://development.galasa.dev/main/maven-repo/isolated). It can then be extracted. The Docker image for this is [here](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-isolated-zip/artifacts-tab).

The Docker image for the mvp build is [here](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-mvp/artifacts-tab). The mvp is similar to isolated but contains only the most used and most stable managers and tests.

The mvp zip file can be downloaded from [here](https://development.galasa.dev/main/maven-repo/mvp). It can then be extracted. The Docker image for this is [here](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-mvp-zip/artifacts-tab).

**Managers**

These pipelines build the [Galasa Managers](https://github.com/galasa-dev/managers)

pr-managers:
1. git-verify
1. clone-automation
1. clone-managers
1. get-commit
1. gradle-build-managers
1. docker-build-managers
1. git-status

branch-managers:
1. clone-automation
1. clone-managers
1. get-commit
1. branch-gradle-build-managers
1. branch-docker-build-managers
1. recycle-deployment
1. wait-deployment
1. trigger-obr

The Docker image for the Managers Maven repo is [here](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-managers/artifacts-tab).

The Managers Maven repository is [here](https://development.galasa.dev/main/maven-repo/managers).


**Maven**

These pipelines build the [Galasa Maven plug-in](https://github.com/galasa-dev/maven)

pr-maven:
1. git-verify
1. clone-automation
1. clone-maven
1. get-commit
1. maven-gpg
1. maven-build-maven
1. docker-build-maven
1. git-status

branch-maven:
1. clone-automation
1. clone-maven
1. get-commit
1. maven-gpg
1. branch-maven-build-maven
1. branch-docker-build-maven
1. recycle-deployment
1. wait-deployment
1. trigger-framework

The Docker image for the Maven Maven repo is [here](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-maven/artifacts-tab).

The Maven Maven repository is [here](https://development.galasa.dev/main/maven-repo/maven).


**OBR**

These pipelines build the Galasa OSGi Bundle Repository (OBR) and the Javadoc for Galasa. Both are stored in the [OBR repository](https://github.com/galasa-dev/obr).

The Javadoc is deployed to a Maven repository as a zip file, and also a Javadoc site.

pr-obr:
1. git-verify
1. clone-automation
1. clone-framework
1. clone-extensions
1. clone-managers
1. clone-obr
1. maven-gpg
1. get-commit
1. generate-bom
1. list-bom
1. maven-build-bom
1. generate-obr
1. list-obr
1. maven-build-obr
1. docker-build-obr
1. generate-javadoc
1. maven-build-javadoc
1. docker-build-javadoc-site
1. docker-build-javadoc-maven-repo
1. git-status

branch-obr:
1. clone-automation
1. clone-framework
1. clone-extensions
1. clone-managers
1. clone-obr
1. maven-gpg
1. get-commit
1. generate-bom
1. list-bom
1. branch-maven-build-bom
1. generate-obr
1. list-obr
1. branch-maven-build-obr
1. branch-docker-build-obr
1. recycle-obr-deployment
1. wait-obr-deployment
1. generate-javadoc
1. maven-build-javadoc
1. docker-build-javadoc-site
1. docker-build-javadoc-maven-repo
1. recycle-javadoc-maven-repo
1. wait-javadoc-maven-repo
1. recycle-javadoc-site
1. recycle-javadoc-site

The Docker image for the OBR Maven repo is [here](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-obr/artifacts-tab).

The OBR Maven repository is [here](https://development.galasa.dev/main/maven-repo/obr).


**OBR Generic**

These pipelines build a generic Galasa OSGi Bundle Repository (OBR) and place it inside the bootEmbedded and ibmBootEmbedded images, which are used for running Galasa tests.

pr-obr:
1. git-verify
1. clone-automation
1. clone-framework
1. clone-extensions
1. clone-managers
1. clone-obr
1. maven-gpg
1. generate-embedded
1. maven-build-obr-generic
1. docker-build-obr-generic
1. copy-files
1. docker-build-amd64-embedded
1. docker-build-ibm-embedded
1. git-status

branch-obr:
1. clone-automation
1. clone-framework
1. clone-extensions
1. clone-managers
1. clone-obr
1. maven-gpg
1. generate-embedded
1. branch-maven-build-obr-generic
1. branch-docker-build-obr-generic
1. copy-files
1. branch-docker-build-amd64-embedded
1. branch-docker-build-ibm-embedded


**Simplatform**

These pipelines build the Galasa SimBank Eclipse plug-in, Simbank applications (_to-do_) and and set of sample Simbank tests, all stored in the [Simplatform repository](https://github.com/galasa-dev/simplatform).

pr-simplatform:
1. git-verify
1. clone-automation
1. clone-simplatform
1. get-commit
1. maven-build-simplatform-application
1. maven-build-simbank-tests
1. docker-build-simplatform-repo
1. docker-build-simplatform-jar
1. git-status

branch-simplatform:
1. clone-automation
1. clone-simplatform
1. get-commit
1. branch-maven-build-simplatform-application
1. branch-maven-build-simbank-tests
1. branch-docker-build-simplatform-repo
1. branch-docker-build-simplatform-jar
1. recycle-deployment
1. wait-deployment

The Docker image for the Simplatform Maven repo is [here](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-simplatform/artifacts-tab) and the image for the Simplatform AMD64 jar is [here](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-simplatform-amd64/artifacts-tab).

The Simplatform Maven repository is [here](https://development.galasa.dev/main/maven-repo/simplatform).


**Wrapping**

These pipelines build the [Wrapping repository](https://github.com/galasa-dev/wrapping). This repository wraps external Galasa dependencies that are not in an OSGi bundle into an OSGi bundle so it can be ran in Galasa.

pr-wrapping:
1. git-verify
1. clone-automation
1. clone-wrapping
1. get-commit
1. maven-gpg
1. maven-build-wrapping
1. docker-build-wrapping
1. git-status

branch-wrapping:
1. clone-automation
1. clone-wrapping
1. get-commit
1. maven-gpg
1. branch-maven-build-wrapping
1. branch-docker-build-wrapping
1. recycle-deployment
1. wait-deployment
1. trigger-gradle

The Docker image for the Wrapping Maven repo is [here](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-wrapping/artifacts-tab).

The Wrapping Maven repository is [here](https://development.galasa.dev/main/maven-repo/wrapping).


## Tasks

### argocd-cli

This task uses the Argo CD CLI to interact with resources that are managed by Argo CD, including resources for our Maven repositories. 

Parameters:
* server: The argocd server to perform the command on.
* command: An array of each part of the argocd command to execute.

This task uses the custom [argocd-cli image](https://harbor.galasa.dev/harbor/projects/5/repositories/argocd-cli/artifacts-tab). 


### copy

This task performs a simple copy from one location to another.

Parameters:
* context: The directory to perform the command in
* source: The from location.
* destination: The to location.

This task uses the latest [busybox image](https://hub.docker.com/_/busybox).


### galasabld

This task uses the galasabld CLI to perform galasabld commands, such as galasabld template.

Parameters:
* context: The directory to perform the command in.
* command: An array of all of the parts of the command.

This task uses the custom [galasabld image](https://harbor.galasa.dev/harbor/projects/5/repositories/galasabld/artifacts-tab).


### get-commit

This task gets the latest git commit hash from the provided repository, and stores it in a location in the workspace.

Parameters:
* pipelineRunName: The name of the currently running PipelineRun, from the PipelineRun context, to find the working directory.
* repo: The name of the GitHub repository.

This task uses the custom [gitcli image](https://harbor.galasa.dev/harbor/projects/5/repositories/gitcli/artifacts-tab).


### git-clean

This task cleans a provided subdirectory from the workspace.

Parameters:
* subdirectory: The subdirectory of the workspace to clean.

This task uses the latest [busybox image](https://hub.docker.com/_/busybox).

_All uses of this task have been commented out as the pipelines use a volumeClaimTemplate which is provisioned for each pipeline, so it is not important to clear up after a pipeline. However, if in future a PersistentVolumeClaim is used in the pipelines, git-clean will need to be used so that the storage is kept clean._


### git-clone

This task clones a GitHub repository from the provided URL into the workspace.

_More documentation to be written._ 


### git-status

This task calls the github-status Go program with parameters extracted from the GitHub webhook payload, and sends the status of a PR build pipeline from Tekton to the pull request on GitHub. The status is updated and a comment is posted to the pull request.

Parameters:
* status: The status of the Tasks from the Tekton pipeline. It is only a Success if all Tasks passed.
* prUrl: The URL of the pull request on GitHub.
* statusesUrl: The URL to return the status of the build to the pull request via a POST request.
* issueUrl: The URL to return comments to the pull request via a POST request.

This task uses the custom [ghstatus image](https://harbor.galasa.dev/harbor/projects/5/repositories/ghstatus/artifacts-tab).


### git-verify

This task calls the github-verify Go program with parameters extracted from the GitHub webhook payload, to verify if a user who opens a pull request into a repository, is an approved code-committer or code-admin, before proceeding with a build. If the user is an approved user, the PR build proceeds, if not, a comment is posted to the pull request informing the author that the PR needs to be approved for building.

Parameters:
* userId: The user ID of the GitHub user who has opened the pull request.
* prUrl: The URL of the pull request on GitHub.
* action: Describes whether the pull request is opened, closed, synchronized etc.

This task uses the custom [ghverify image](https://harbor.galasa.dev/harbor/projects/5/repositories/ghverify/artifacts-tab).


### go-build

This task is used to build Go code. 

Parameters:
* context: Describes the path to the Go code to build.
* goArgs: Include the Go command to be executed such as build or install, and any other flags and arguments needed.
* The other paramters are all environment variables which have default values and can be overwritten if necessary.

This task uses the latest official [GoLang image](https://hub.docker.com/_/golang).


### gradle-build

This task executes a Gradle build. It is generic and allows for parameters to dictate the exact type of build.

Parameters:
* context: The directory where you want the Gradle build to take place (where the gradle.build file is).
* build-args: An array used to pass any additional arguments to the Gradle build.
* command: An array of commands to use in the build such as 'publish' and 'check'.

This task uses the offical [Gradle image](https://hub.docker.com/_/gradle) from DockerHub.


### kaniko-builder

This task allows you to build and push Docker images within a Kubernetes cluster or container. This is needed as Docker virtualisation cannot be performed inside a containerised environment.

Parameters:
* dockerfilePath: The path to the Dockerfile needed for the build.
* imageName: The name to give the image after it is built, including the tag.
* noPush: Allows you to choose whether you want to push the image built to the given destination (dockerRegistry/imageName).
* buildArgs: An array used to pass any build arguments needed into the Dockerfile.

The task uses [kaniko-executor image](https://console.cloud.google.com/gcr/images/kaniko-project/GLOBAL/executor@sha256:23ae6ccaba2b0f599966dbc5ecf38aa4404f4cd799add224167eaf285696551a/details?tag=latest), from gcr.io (Google Container Registry).


### make

This task is used to perform the shell command 'make all' to execute a Makefile.

Parameters:
* directory: The directory to perform the command in.

This task uses the official [GoLang image](https://hub.docker.com/_/golang).


### maven-build

This task performs a Maven build. It is generic and allows for parameters to dictate the exact type of build.

Parameters:
* context: The directory where you want the Maven build to take place (where the pom.xml file is).
* settingsLocation: The location of the settings.xml produced by the maven-gpg task. This will normally be /workspace/git/PIPELINE_RUN_NAME/REPO/gpg/settings.xml. For the OBR builds, as two Maven builds occur in two different contexts, to avoid doing maven-gpg twice, the settingsLocation is set.
* buildArgs: An array used for any additional arguments to pass to Maven.
* command: An array of commands to use in the build such as 'deploy' or 'install'.

This task uses the offical [Maven image](https://hub.docker.com/_/maven) from DockerHub.


### maven-gpg

The Maven build uses the Maven GPG Plugin to sign all of the built artifacts using GnuPG. This task uses the GnuPG CLI to put the correct secrets in place for the Maven GPG Plugin to use during the maven-build task. This task uses the ExternalSecret mavengpg.

1. The first step makes a new directory within the provided working directory.
1. The second step performs a gpg command to import the passphrase and gpg key.
1. In the last step, the settings.xml from the mavengpg secret that has been populated with the galasa.passphrase is copied and put in the directory made in the first step.

Parameters:
* context: The location to store the settings.xml for use by a Maven build.

This task uses the custom [gpg image](https://harbor.galasa.dev/harbor/projects/5/repositories/gpg/artifacts-tab). This task also uses the offical [busybox image](https://hub.docker.com/_/busybox) from DockerHub to perform Unix commands.


### recycle-deployment

This task uses the kubectl CLI to recycle deployments on the cluster. 

Parameters:
* namespace: The name of the Kubernetes Namespace.
* deployment: The name of the Kubernetes Deployment.

This task uses the custom [kubectl image](https://harbor.galasa.dev/harbor/projects/5/repositories/kubectl/artifacts-tab).


### script

This task is used to perform a script.

Parameters:
* context: The directory to perform the command in.
* script: A string containing the script to be performed
* image: By default this uses busybox to contain most commands likely needed. However if other commands are needed then a custom image can be passed here.

This task, by default, uses the latest [busybox image](https://hub.docker.com/_/busybox). Unless, an image is passed as a paramter.

### tkn-cli

This task is used the Tekton CLI to communicate with Tekton.

Parameters:
* context: The directory to perform the command in.
* command: An array with the parts of the command to perform.

This task uses the custom [tkn image](https://harbor.galasa.dev/harbor/projects/5/repositories/tkn/artifacts-tab).


### unix-command

This task is used to perform Unix commands. 

Parameters:
* context: The directory to perform the command in.
* command: An array with the parts of the command to perform.

This task uses the latest [busybox image](https://hub.docker.com/_/busybox).