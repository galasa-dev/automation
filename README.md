# Galasa Automation Repository

This repository is the single location for all the automation and CI/CD that occurs in Galasa. It currently breaks down into:
1. build-images - any custom images required for the build process
1. dockerfiles - all the organised dockerfiles for all the images built for galasa
1. infrastructure - all the galasa infrastructure as code, including all the kubernetes setup
1. pipelines - all the tekton components

# Pipelines

## Event Listeners

### github-pr-builder-listener

This EventListener is triggered via webhook when a pull request is opened in a repository.

If a pull request is opened by someone who is not part of an approved group (code admins or code committers), building of the PR will be blocked, until a code admin has commented on the PR 'Approved for building'.
### github-pr-review-builder-listener

???

### github-main-builder-listener

This EventListener is triggered via webhook when code is pushed into the 'main' branch of a repository.

## Pipelines

Jade comment - for the pipeline's I would mention
a) the different tasks, just in passing though as you'll go more into detail about each task later, so for example 'The PR pipelines do the git-verify task first to see who the PR was opened by, so whether it can be built straight away or if it needs approval from a Galasa code admin'
b) what does the pipeline build and produce? So they all do either a Maven or Gradle build, what does that produce and where do those artifacts get put? There's a docker build, say where that image gets pushed and what is it tagged. I'd include a link to harbor, like 'The Wrapping Docker image that is built in this pipeline is pushed to our image registry [harbor](harbor.galasa.dev/galasadev/galasa-wrapping) and is tagged ........'
c) For PR pipelines, mention that git-status is the mechanism which sends back to the PR on Github whether the PR build was successful or failed
d) automation will be slightly different as we are just building the docker images for each of our custom images, so just talk a little about what image does and what commands it allows us to run

### pr-<repository>

If a pr is opened in one of Galasa's repositories, the pr-build pipeline for that repository will be invoked.
Every pr build follows similar a structure that make use of generic tasks that can be sibstituted in when needed to keep pipelines more maintainable. However more detail about each pipeline is documented below as there are repository specific components.
Every pr build will incorporate the following tasks:
The pipeline will first use the 'git-verify' task to see if the pr author needs approval from a Galasa admin.
The next task is to clone the repository where the pr is opened and clone the automation repository. 
Then the 'get-commit' task is called to get the latest commit of the repository.
A maven or gradle build is then performed depending on the repository to build the repository artifact.
Then a docker build task is used to build the image of the repository with the pr's changes and is then pushed to harbor, tagging the image with the latest commit SHA in the pr.
Finally, a 'git-status' task is always run which sends back to the PR on Github whether the PR build was successful or failed.
A git-clean is then performed on the repositories that were cloned.

### main-<repository>#

When there is a push to the main branch of a repository, the main build is for that repository is invoked.
Every main build follows similar a structure that make use of generic tasks that can be sibstituted in when needed to keep pipelines more maintainable. However more detail about each pipeline is documented below as there are repository specific components.
Every main build will incorporate the following tasks:
The first task is to clone the repository where the push to main occurred and clone the automation repository. 
Then the 'get-commit' task is called to get the latest commit of the repository.
A maven or gradle build is then performed depending on the repository to build the repository artifact.
Then a docker build task is used to build the image of the main branch of the repository including the recent pushed changes and is pushed to harbor with the tag 'main' and deployed to the remote maven repository. This is so we can distinguish the image from ones built from pull requests and will also be use to deploy to the remote maven repository.
We then perform the 'recycle-deployment' task which ***************
Finally, a git-clean is then performed on the repositories that were cloned.

### pr-automation

The pr automation build is different to the other repositories.
This pipeline is triggered when  pr is opened in the automation repository.
It still initially uses the tasks: 'git-verify', clones the automation repository and then 'get-commit'.
However, we then do a series of docker-builds to build and push the custom images we need to [harbor](harbor.galasa.dev/common), tagged with the latest commit SHA of the pr. These images allow you to run certain commands in other pipelines. 
For example the gpg-image is an image purely with the capabitlty to run gpg commands. This is needed in the generic 'maven-gpg' task whihc in turn is needed for the 'maven-build' task. This modularity of tasks makes pipelines much easier to compose as it can use tasks already made and pass in the specific parameters it requires.

### main-automation

The main automation build is different to the other repositories.
This pipeline is triggered when there is a push to the main branch in the automation repository.
We still initially clone the automation repository, but we then do a series of docker builds for the custom images which we then push to [harbor](harbor.galasa.dev/common), with the tag 'main'.
Fianlly, we perform the task 'git-clean' 

### pr-wrapping

This Pipeline is triggered when a pull request is opened in the [Wrapping repository](https://github.com/galasa-dev/wrapping).

This pipeline will follow the structure of a pr build as mentioned above. 
It will have two 'git-clone' tasks, cloning the Automation and Wrapping repositories.

This build requires a maven build. Therefore, another task is needed - 'maven-gpg' - prior to performing the 'maven-build' task.

We then perform a docker build and the image is then pushed to [harbor](harbor.galasa.dev/galasadev/galasa-wrapping) and is tagged with the latest commit SHA in the pr so the image is easily identifyable.

Finally, the 'git-status' task is run which sends back to the PR on Github whether the PR build was successful or failed.
We can then perform the 'git-clean' task on the Automation and Wrapping repositories.

### main-wrapping

This pipelines is triggered when there is a push to the main branch of the Wrapping repository.

This pipeline will follow the structure of a main build as mentioned above.
It will have two 'git-clone' tasks, cloning the Automation and Wrapping repositories.

This build requires a maven build. Therefore, another task is needed - 'maven-gpg' - prior to performing the 'maven-build' task. We set the command in the maven-build to be 'deploy'.

We then perform a docker build and the image is then pushed to [harbor](harbor.galasa.dev/galasadev/galasa-wrapping) and is tagged with 'main'.

We then perform the 'recycle-deployment' task perform a rolling restart of the wrapping deployment to make sure the new 'galasa-wrapping:main' image is deployed to the [remote maven repository](development.galasa.dev/main/maven/wrapping).

Finally we perform the 'git-clean' task on the Automation and Wrapping repositories.

### pr-gradle

This Pipeline is triggered when a pull request is opened in the [Gradle repository](https://github.com/galasa-dev/gradle).

This pipeline will following the structure above. 
It will have two 'git-clone' tasks, cloning the Automation and Gradle repositories.

This build requires a gradle build. We use the generic task 'gradle-build' and pass in the necessary parameters revelant to the gradle repository.

We then perform a docker build and the image is then pushed to [harbor](harbor.galasa.dev/galasadev/galasa-gradle) and is tagged with the latest commit SHA in the pr so the image is easily identifyable.

### main-gradle

This pipelines is triggered when there is a push to the main branch of the Gradle repository.

This pipeline will follow the structure of a main build as mentioned above.
It will have two 'git-clone' tasks, cloning the Automation and Gradle repositories.

This build requires a gradle build. We use the 'gradle-build' task and pass in the command 'publish'.

We then perform a docker build and the image is then pushed to [harbor](harbor.galasa.dev/galasadev/galasa-gradle) and is tagged with 'main'.

We then perform the 'recycle-deployment' task perform a rolling restart of the gradle deployment to make sure the new 'galasa-gradle:main' image is deployed to the [remote maven repository](development.galasa.dev/main/maven/gradle).

Finally we perform the 'git-clean' task on the Automation and Gradle repositories.

### pr-maven

This Pipeline is triggered when a pull request is opened in the [Maven repository](https://github.com/galasa-dev/maven).

This pipeline will following the structure above. 
It will have two 'git-clone' tasks, cloning the Maven and Wrapping repositories.

This build requires a maven build. Therefore, another task is needed - 'maven-gpg' - prior to performing the 'maven-build' task.

We then perform a docker build and the image is then pushed to [harbor](harbor.galasa.dev/galasadev/galasa-maven) and is tagged with the latest commit SHA in the pr so the image is easily identifyable.

### main-maven

This pipelines is triggered when there is a push to the main branch of the Maven repository.

This pipeline will follow the structure of a main build as mentioned above.
It will have two 'git-clone' tasks, cloning the Automation and Maven repositories.

This build requires a maven build. Therefore, another task is needed - 'maven-gpg' - prior to performing the 'maven-build' task. We set the command in the maven-build to be 'deploy'.

We then perform a docker build and the image is then pushed to [harbor](harbor.galasa.dev/galasadev/galasa-maven) and is tagged with 'main'.

We then perform the 'recycle-deployment' task perform a rolling restart of the maven deployment to make sure the new 'galasa-maven:main' image is deployed to the [remote maven repository](development.galasa.dev/main/maven/maven).

Finally we perform the 'git-clean' task on the Automation and Maven repositories.

## Tasks

Jade comment - for the tasks I would write about
a) what the parameters are that you pass in for each task
b) what the image is that we use for the task, whether it's a custom one we have made to run a certain command, or if its just a docker official image we are pulling from Dockerhub
c) just an explanation of what the steps do, doesn't have to be super technical

### get-commit

### git-clean

### git-clone

This task clones a repository given by a URL.

### git-status

This task provides that status of a pr build - whether it passed or failed.

Parameters:
We pass the status of the tasks from a pipeline.
We get the prUrl, statusesUrl and IssueUrl from the webhook that triggered the pipeline that uses this git-status task.

Uses the custom ghgstatus image from harbor

### git-verify

This task is to verify a user when they open a pr into a repository.

### go-make

This task is to purely perform the command 'make'.

The task's only paramter is directory that we are performing the make command in.

It uses the official go image from DockerHub to be able to perform go commands.

### gradle-build

This task performs a gradle build. It is generic and allows for parameters to dictacte the exact functionality of the build. Therefore, it is a highly reusable task.

Parameters:
We pass the 'context' which is the directory where you want the gradle build to take place (where the gradle.build file is).
We pass in an array, 'build-args', for any additional arguments we like to pass to gradle. We have this parameter to keep the gradle-build task as generic as possible so it can be used in any build situation that requires gradle.
We then finally pass in the command we want to use such as 'publish' or 'build'

We pull and use the offical gradle image from DockerHub in order to perform the gradle commands.

### kaniko-builder

This task allows you to build and push docker images within a kubernetes cluster or container.

Parameters:
The dockerfilePath is the path to the dockerfile needed for the build.
The imageName is the name of the image that the task is going to build.
The noPush parameter allows you to choose whether you want to push the image built to the given destination (imageName).
We pass an array, 'build-args', to pass any arguments needed into the dockerfile.

The task uses kaniko-executor image to perform kaniko commands.

### maven-build

This task performs a maven build. It is generic and allows for parameters to dictacte the exact functionality of the build. Therefore, it is a highly reusable task.

Parameters:
We pass the 'context' which is the directory where you want the maven build to take place (where the pom.xml file is).
We pass in an array, 'build-args', for any additional arguments we like to pass to maven. We have this parameter to keep the maven-build task as generic as possible so it can be used in any build situation that requires maven.
We then finally pass in the command we want to use such as 'deploy' or 'install'

We pull and use the offical maven image from DockerHub in order to perform the maven commands.

### maven-gpg

The Maven build uses the Maven GPG Plugin to sign all of the built artifacts using GnuPG. The maven-gpg task uses the GnuPG CLI to put the correct secrets in place for the Maven GPG Plugin to use during the maven-build task.

 uses the ExternalSecret 'mavengpg' and maybe have a path to the yaml? maven-gpg task pulls out two bits of data (passphrase and gpg key) from our IBM Cloud Secrets Manager and puts them into a settings.xml file, for the Maven GPG Plugin to use.

This task has three steps:


### recycle-deployment

This task performs a kubernetes rolling restart of the given deployment which shuts down and restarts each container in the deployment one by one.
It then outputs the status of the rolling restart #######after 3 minutes of waiting########

Parameters:
This task takes the deployment name that we want to perform the rollout restart commands on.

We pull the custom kubectl image that is stored in harbor. We use the image that is tagged with main as we know this is the latest working version of this image.