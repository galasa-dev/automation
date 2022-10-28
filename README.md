# Galasa Automation Repository
No Change PR
This repository is the single location for all the automation and CI/CD that occurs in Galasa. It currently breaks down into:
1. build-images - any custom images required for the build process
1. dockerfiles - all the organised dockerfiles for all the images built for galasa
1. infrastructure - all the galasa infrastructure as code, including all the kubernetes setup
1. pipelines - all the tekton components


# Pipelines

**This documentation is a work in progress and will continue being added to as new build pipelines are developed.**


## Event Listeners

Webhooks are set up on these Github repositories to trigger the three EventListeners:
- Automation
- Wrapping
- Gradle
- Maven
- Framework (Pipeline not running yet)
- Extensions (Pipeline not running yet)
- Managers (Pipeline not running yet)
- OBR (Pipeline not running yet)
- Eclipse (Pipeline not running yet)
- Isolated (Pipeline not running yet)


### github-pr-builder-listener

This EventListener is triggered via webhook when a pull request is opened in a repository.

If a pull request is opened by someone who is not part of an approved group (code admins or code committers), building of the PR will be blocked, until a code admin has commented on the PR 'Approved for building'. Otherwise, this will trigger a PR build.


### github-pr-review-builder-listener

This EventListener is triggered via webhook when a code-admin submits the 'Approved for building' comment on a pull request that was blocked from building. This will then trigger a PR build.


### github-main-builder-listener

This EventListener is triggered via webhook when code is pushed into the main branch of a repository, and triggers a Main build of that repository.


## Pipelines

### Automation repository

The build pipelines for the Automation repository are different to the build pipelines for the other repositories, as the Automation repository stores resources for the automation and CI/CD within Galasa, not source code. 

### pr-automation

This pipeline is triggered when a pull request is opened in the Automation repository.

1. The pipeline starts by running the task 'git-verify'.

1. The pipeline then clones the Automation repository.

1. The 'get-commit' task is ran.

1. Unlike the other pipelines, no Maven or Gradle build is required. A series of 'docker-build' tasks are ran to build and push the custom images needed in the pipelines to [harbor](https://harbor.galasa.dev/harbor/projects/5/repositories). These images are tagged with the commit hash from the last commit in the pull request.

1. 'git-status' returns the status of the build to the pull request.

1. 'git-clean' cleans the subdirectory that automation was cloned into.


### main-automation

This pipeline is triggered when there is a push to the main branch in the Automation repository.

1. The pipeline starts by cloning the Automation repository.

1. A series of 'docker-build' tasks are ran concurrently to build the custom images which are then pushed to [harbor](https://harbor.galasa.dev/harbor/projects/5/repositories). These images are tagged main.

1. 'git-clean' cleans up the subdirectory where automation was cloned.

The custom images that are built as part of this pipeline give the capability to run certain commands in other pipelines. 

For example, the gpg image is an image made purely for the capability to run GnuPG CLI commands. This is needed for the 'maven-gpg' task which in turn is needed for the 'maven-build' task. This modularity of tasks makes pipelines much easier to compose as it can use tasks already made and pass in the specific parameters it requires.


### Other repositories

### PR builds (pr-*repository*)

If a pull request is opened in one of Galasa's repositories on Github, the pr-build pipeline for that repository will be invoked.

Every PR build follows similar a structure that make use of generic tasks that can be substituted in when needed to keep pipelines more maintainable. However more detail about each pipeline is documented below as there are repository specific components.

PR builds (excluding pr-automation) involve the following tasks:

1. The pipeline will first run the 'git-verify' task to see if the pull request author is in the approved group.

1. The next task is a 'git-clone' to clone the Automation repository, as all resources used in the build pipelines are stored there.

1. The next task is a 'git-clone' to clone the repository where the pull request was opened.

1. The 'get-commit' task outputs and stores the latest git commit hash of the repository.

1. **If the repository is built using Maven:** the 'maven-gpg' task is ran first to put in place the GPG key for signing artifacts, followed by the 'maven-build' task. **If the repository is built using Gradle:** the 'gradle-build' task is ran.

1. The 'docker-build' task is used to build the docker image of the repository with the pull request's code and is then pushed to our image registry, [harbor](harbor.galasa.dev), tagging the image with the commit hash from the 'get-commit' task.

1. The 'git-status' task updates the status of the pull request on Github and comments whether the PR build was successful or failed.

1. 'git-clean' is then performed in any subdirectories where repositories were cloned to keep the PVC clean.


### pr-wrapping

This pipeline is triggered when a pull request is opened in the [Wrapping repository](https://github.com/galasa-dev/wrapping).

This pipeline follows the structure of a PR build as mentioned above. 

The Wrapping repository requires a Maven build. Therefore, the 'maven-gpg' task is ran followed by a 'maven-build'.

The 'docker-build' task builds the [galasa-wrapping image](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-wrapping/artifacts-tab) and pushes it to harbor. The image is tagged with the commit hash from the last commit in the pull request.


### pr-gradle

This pipeline is triggered when a pull request is opened in the [Gradle repository](https://github.com/galasa-dev/gradle).

This pipeline follows the structure of a PR build as mentioned above. 

The Gradle repository requred a Gradle build. Therefore, the 'gradle-build' task is ran in this pipeline.

The 'docker-build' task builds the [galasa-gradle image](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-gradle/artifacts-tab) and pushes it to harbor. The image is tagged with the commit hash from the last commit in the pull request.


### pr-maven

This pipeline is triggered when a pull request is opened in the [Maven repository](https://github.com/galasa-dev/maven).

This pipeline follows the structure of a PR build as mentioned above. 

The Maven repository requires a Maven build. Therefore, the 'maven-gpg' task is ran followed by a 'maven-build'.

The 'docker-build' task builds the [galasa-maven image](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-maven/artifacts-tab) and pushes it to harbor. The image is tagged with the commit hash from the last commit in the pull request.


### Main builds (main-*repository*)

When there is a push to the main branch of a repository, the Main build for that repository is invoked.

Every Main build follows similar a structure that make use of generic tasks that can be substituted in when needed to keep pipelines more maintainable. However more detail about each pipeline is documented below as there are repository specific components.

Main builds (excluding main-automation) involve the following tasks:

1. The first task is a 'git-clone' to clone the Automation repository, as all resources used in the build pipelines are stored there.

1. The next task is a 'git-clone' to clone the repository where the main branch was pushed to.

1. The 'get-commit' task outputs and stores the latest git commit hash of the repository.

1. **If the repository is built using Maven:** the 'maven-gpg' task is ran first to put in place the GPG key for signing artifacts, followed by the 'maven-build' task. **If the repository is built using Gradle:** the 'gradle-build' task is ran.

1. The 'docker-build' task is used to build the image of the main branch of the repository. The image is tagged main, and is pushed to harbor. This is so we can easily distinguish the main image from other images built from pull requests, branch builds, etc. The main image is also used as the container for the Deployments, which deploy Maven artifacts to the [Maven artifact repository](development.galasa.dev).

1. The 'recycle-deployment' task performs a kubectl rolling restart of the Deployment which hosts the Maven artifact repository for the repository.

1. Finally, a 'git-clean' is then performed on the subdirectories where repositories were cloned.


### main-wrapping

This pipeline is triggered when there is a push to the main branch of the Wrapping repository.

This pipeline follows the structure of a Main build as mentioned above.

This repository requires a Maven build. Therefore, 'maven-gpg' is ran prior to running the 'maven-build' task. The command in the maven-build is 'deploy', to add the built artifacts to the remote Maven artifact repository.

This pipeline runs 'docker-build' to build the galasa-wrapping image, which is then pushed to [harbor](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-wrapping/artifacts-tab) and is tagged as main.

Then the 'recycle-deployment' task performs a rolling restart of the maven-wrapping Deployment to make sure the latest 'galasa-wrapping:main' image is deployed to the [remote Maven artifact repository](development.galasa.dev/main/maven/wrapping).


### main-gradle

This pipeline is triggered when there is a push to the main branch of the Gradle repository.

This pipeline follows the structure of a Main build as mentioned above.

This repository requires a Gradle build. Therefore, 'gradle-build' is ran, with the command 'publish', to publish built artifacts to the remote Maven artifact repository.

This pipeline runs 'docker-build' to build the galasa-gradle image, which is then pushed to [harbor](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-gradle/artifacts-tab) and is tagged as main.

Then the 'recycle-deployment' task performs a rolling restart of the maven-gradle Deployment to make sure the latest 'galasa-gradle:main' image is deployed to the [remote Maven artifact repository](development.galasa.dev/main/maven/gradle).


### main-maven

This pipeline is triggered when there is a push to the main branch of the Maven repository.

This pipeline follows the structure of a Main build as mentioned above.

This repository requires a Maven build.

This pipeline runs 'docker-build' to build the galasa-maven image, which is then pushed to [harbor](https://harbor.galasa.dev/harbor/projects/3/repositories/galasa-maven/artifacts-tab) and is tagged as main.

Then the 'recycle-deployment' task performs a rolling restart of the maven-maven Deployment to make sure the latest 'galasa-maven:main' image is deployed to the [remote Maven artifact repository](development.galasa.dev/main/maven/maven).


## Tasks

### get-commit

This task outputs the latest git commit hash from the provided repository, and stores it in a location in the workspace.

This task uses the custom gitcli image stored in [harbor](https://harbor.galasa.dev/harbor/projects/5/repositories/gitcli/artifacts-tab). This image allows for git commands and is also built on top of the custom gpg image as this task requires both commands. 

### git-clean

This task removes the cleans the provided subdirectory from the workspace.

This task uses the latest busybox image to perform Unix commands.

### git-clone

This task clones a repository from the provided URL into the workspace.

More documentation to be written.

### git-status

This task provides the status of a pull request build - whether it passed or failed - and updates the pull request on GitHub with this status.

The parameters for this task are extracted from the payload of the webhook. These are then passed as parameters to the Go program build-images/github-status/main.go that will then output the appropriate status on the pull request on GitHub.

Parameters:
- The status of the tasks from the pipeline.
- prUrl, the URL of the pull request on Github.
- statusesUrl, the URL to return the status of the build to the pull request via a POST request.
- issueUrl, the URL to return comments to the pull request via a POST request.

This task uses the custom ghgstatus image stored in [harbor](https://harbor.galasa.dev/harbor/projects/5/repositories/ghgstatus/artifacts-tab)

### git-verify

This task is used to verify that a user who opens a pull request into a repository, is an approved code-committer or code-admin, before proceeding with a build.

The parameters for this task are extracted from the payload of the webhook. These are then passed as parameters to the Go program build-images/github-verify/main.go that will then output the appropriate message to the pull request on GitHub.

Parameters:
- The userId of the Github user who has opened the pull request.
- The prUrl, the URL of the pull request on Github.
- The action, describes whether the pull request is opened, closed, synchronized etc.

This task uses the ghgverify Go program to first verify that the action is a supported one. It then checks if the userId is in the approved group. It then returns to the pull request whether the build has been submitted, or if an admin needs to approve.

This task uses the custom ghgverify image stored in [harbor](https://harbor.galasa.dev/harbor/projects/5/repositories/ghgverify/artifacts-tab)

### make

This task is used to perform the shell command 'make all' and execute a Makefile.

Parameters:
- The directory to perform the 'make all' command in.

This task uses the official GoLang image from DockerHub.

### gradle-build

This task performs a Gradle build. It is generic and allows for parameters to dictacte the exact functionality of the build. Therefore, it is a highly reusable task.

Parameters:
- The 'context' which is the directory where you want the Gradle build to take place (where the gradle.build file is).
- An array, 'build-args', is used to pass any additional arguments to the Gradle build. This parameter is to keep the gradle-build task as generic as possible so it can be used in any build situation that requires Gradle.
- The command to use in the build such as 'publish' or 'build'.

This task uses the offical Gradle image from DockerHub in order to perform the Gradle commands.

### kaniko-builder

This task allows you to build and push docker images within a kubernetes cluster or container.

Parameters:
- The dockerfilePath is the path to the Dockerfile needed for the build.
- The imageName is the name of the image that the task is going to build.
- The noPush parameter allows you to choose whether you want to push the image built to the given destination (imageName).
- The array, 'buildArgs', is used to pass any arguments needed into the Dockerfile.

The task uses kaniko-executor image to perform kaniko commands. This image is stored in [harbor](https://harbor.galasa.dev/harbor/projects/5/repositories/kaniko-executor/artifacts-tab).

### maven-build

This task performs a Maven build. It is generic and allows for parameters to dictacte the exact functionality of the build. Therefore, it is a highly reusable task.

Parameters:
- The 'context' which is the directory where you want the Maven build to take place (where the pom.xml file is).
- An array, 'buildArgs', is used for any additional arguments to pass to Maven. This parameter is to keep the maven-build task as generic as possible so it can be used in any build situation that requires Maven.
- The command to use in the build such as 'deploy' or 'install'.

This task uses the offical Maven image from DockerHub in order to perform the Maven commands.

### maven-gpg

The Maven build uses the Maven GPG Plugin to sign all of the built artifacts using GnuPG. The maven-gpg task uses the GnuPG CLI to put the correct secrets in place for the Maven GPG Plugin to use during the maven-build task. This task uses the ExternalSecret mavengpg.

1. The first step makes a new directory within the provided working directory.
1. The second step performs a gpg command to import the passphrase and gpg key.
1. In the last step, the settings.xml from the mavengpg secret that has been populated with the galasa.passphrase is copied and put in the directory made in the first step.

Parameters:
- The context which is the directory to store the settings.xml for use by a Maven build.

This task uses the custom gpg image stored in [harbor](https://harbor.galasa.dev/harbor/projects/5/repositories/gpg/artifacts-tab) to perform gpg commands.
This task also uses the offical busybox image from DockerHub to perform Unix commands.


### recycle-deployment

1. This task performs a kubernetes rolling restart of the given deployment which shuts down and restarts each container in the deployment one by one.
1. It then outputs the status of the rolling restart. If no status is returned within 3 minutes, it will timeout.

Parameters:
- This task takes the deployment name to perform the rollout restart commands on.

This task uses the custom kubectl image that is stored in [harbor](https://harbor.galasa.dev/harbor/projects/5/repositories/kubectl/artifacts-tab). 
