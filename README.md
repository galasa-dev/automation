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

### pr-automation

### main-automation

### pr-wrapping

This Pipeline is triggered when a pull request is opened in the [Wrapping repository](https://github.com/galasa-dev/wrapping).

### main-wrapping

### pr-gradle

This Pipeline is triggered when a pull request is opened in the [Gradle repository](https://github.com/galasa-dev/gradle).

### main-gradle

### pr-maven

This Pipeline is triggered when a pull request is opened in the [Maven repository](https://github.com/galasa-dev/maven).

### main-maven

## Tasks

Jade comment - for the tasks I would write about
a) what the parameters are that you pass in for each task
b) what the image is that we use for the task, whether it's a custom one we have made to run a certain command, or if its just a docker official image we are pulling from Dockerhub
c) just an explanation of what the steps do, doesn't have to be super technical
