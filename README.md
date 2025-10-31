# Galasa Automation Repository

This repository is the single location for all the automation and CI/CD that occurs in Galasa. 

Find out more about:
1. [build-images](#build-images): Custom images required for the build process
1. [dockerfiles](#dockerfiles): The organised Dockerfiles for all the images built for Galasa
1. [docs](#docs): Documentation pages and images
1. [infrastructure](#infrastructure): The Galasa infrastructure as code, including the Kubernetes set-up
1. [offline-tools](#offline-tools): Source code for the copyright checker tool
1. [pipelines](#pipelines): The CustomResourceDefinitions used in our Tekton build pipelines, ClusterRoles, EventListeners, Pipelines, Roles, ServiceAccounts and Tasks
1. [releasePipeline](#release-pipeline): Scripts, instructions and CustomResourceDefinitions for a Galasa release


# Build-images

This directory holds the Go code for custom build images.

## github-status:

This image provides the status of a pull request build - whether it passed or failed - and updates the pull request on GitHub with this status.

## github-verify:

This image is used to verify that a user who opens a pull request into a repository, is an approved code-committer or code-admin, before proceeding with a build.

## github-webhook-monitor:

This image is used to monitor the galasa-dev organisation-wide webhook for any new deliveries, every 2 minutes. It will then trigger the appropriate EventListener for each delivery to then trigger the corresponding build pipeline.

## github-webhook-receiver: 

This image is used to receive requests from the webhook and responds with a 200 response to avoid the appearance of unsuccessful deliveries.


# Dockerfiles

This directory is the single location for all Dockerfiles needed to build the images Galasa needs.

| Category | Dockerfiles |
|----------|-------------|
| Custom images (If there is not be a Docker official image that allows us to use a tool, we have created custom images to enable this. The Dockerfiles for all of the custom images are in the _dockerfiles/common_ directory) | argocd, ghstatus, ghverify, gitcli, githubmonitor, githubreceiver, gpg, kubectl, openapi, openjdk17ibmgradle, swagger, tkn | 
| Go programs | ghstatus, ghverify, github-webhook-monitor, github-webhook-receiver |
| Base image (Most other images are built on top of this. Used to enable use of the Apache HTTP Server) | base |
| Galasa Resources site | resources |


# Docs

This directory contains images for the documentation and instructions for:
* How to contribute to the project
* How to authenticate a Pull Request to build


# Infrastructure

Galasa's infrastructure is currently spread across two Kubernetes clusters - an internal cluster and an external cluster. 

cicsk8s:
* All Tekton build pipelines are run on the internal cluster.
* The ArgoCD instance which controls all resources for the pipelines (Pipelines, Tasks, etc) is hosted on the internal cluster.

galasa-plan-b-lon02: 
* All Deployments, Services and Ingresses which make up our Maven artifact repositories are hosted on the external cluster.
* The [ArgoCD](argocd.galasa.dev) instance which controls the above resources is hosted on the external cluster.


# Offline Tools

The offline-tools directory contains the source code for the GitHub Copyright Checker tool. Read more [here](./offline-tools/copyrighter/README.md)


# Pipelines

## Cluster Roles

A ClusterRole recycle-ecosystem has been created to recycle the Deployments in the galasa-prod ecosystem.

## Event Listeners

A webhook is set up for the galasa-dev organisation on GitHub. Every 2-minutes, the github-monitor checks for new events delivered to the webhook and triggers one of thee EventListeners where necessary.

_Currently, payload validation has been turned off with an annotation in the metadata for these EventListeners. This is because the github-monitor currently cannot validate the payloads from GitHub. This will be turned on in the future once the github-monitor can validate payloads from GitHub._

### github-main-builder-listener

This EventListener is triggered via webhook when code is pushed into the main branch of the automation repository to look out for changes to the [cps.properties](./infrastructure/cicsk8s/galasa-dev/cps-properties.yaml) file. It triggers the branch-automation Pipeline.


## Pipelines

branch-automation:
The pipeline applies changes to the prod1 Galasa service's CPS properties using `galasactl resources apply` if changes have been made to the [cps.properties](./infrastructure/cicsk8s/galasa-dev/cps-properties.yaml) file.

codecoverage (**this pipeline is inactive and due to be converted into a GitHub Actions workflow**): 
This pipeline generates and deploys a [code coverage report](https://development.galasa.dev/codecoverage) for Galasa based on data from Jacoco.

recycle-prod1:
This pipeline recycles deployments in the prod1 ecosystem: api, testcatalog, engine-controller, resource-monitor and metrics. This is triggered after code is promoted to production so that the ecosystem has the latest Galasa code.

update-prod1:
This pipeline runs a `helm upgrade` to update the prod1 service using the [latest Galasa service Helm chart](https://github.com/galasa-dev/helm). This is triggered after code is promoted to production so that the service has the latest Galasa code.


## Roles

A Role to recycle deployments on the cluster.


## Service Accounts

Definitions for the ServiceAccounts used during pipelines.


## Tasks

### galasabld-command

This task uses the galasabld CLI to perform galasabld commands, such as galasabld template.

Parameters:
* context: The directory to perform the command in.
* command: An array of all of the parts of the command.
* galasabldImageTag: The image tag to use, defaults to main.

This task uses the custom [galasabld image](https://github.com/galasa-dev/galasa/pkgs/container/galasabld-amd64).


### galasactl-command

This task uses the galasactl CLI to perform galasactl commands, such as galasactl runs submit.

Parameters:
* context: The directory to perform the command in.
* command: An array of all of the parts of the command.
* galasactlImageTag: The image tag to use, defaults to main.

This task uses the custom [galasactl image](https://github.com/galasa-dev/cli/pkgs/container/galasactl-x86_64).


### git-clone

This task clones a GitHub repository from the provided URL into the workspace.


### git-status

This task calls the github-status Go program with parameters extracted from the GitHub webhook payload, and sends the status of a PR build pipeline from Tekton to the pull request on GitHub. The status is updated and a comment is posted to the pull request.

Parameters:
* status: The status of the Tasks from the Tekton pipeline. It is only a Success if all Tasks passed.
* prUrl: The URL of the pull request on GitHub.
* statusesUrl: The URL to return the status of the build to the pull request via a POST request.
* issueUrl: The URL to return comments to the pull request via a POST request.
* pipelineRunName: The PipelineRun name triggered by the PR.

This task uses the custom [ghstatus image](https://github.com/galasa-dev/automation/pkgs/container/ghstatus).


### git-verify

This task calls the github-verify Go program with parameters extracted from the GitHub webhook payload, to verify if a user who opens a pull request into a repository, is an approved code-committer or code-admin, before proceeding with a build. If the user is an approved user, the PR build proceeds, if not, a comment is posted to the pull request informing the author that the PR needs to be approved for building.

Parameters:
* userId: The user ID of the GitHub user who has opened the pull request.
* prUrl: The URL of the pull request on GitHub.
* action: Describes whether the pull request is opened, closed, synchronized etc.

This task uses the custom [ghverify image](https://github.com/galasa-dev/automation/pkgs/container/ghverify).


### kaniko-builder

This task allows you to build and push Docker images within a Kubernetes cluster or container. This is needed as Docker virtualisation cannot be performed inside a containerised environment.

Parameters:
* pipelineRunName: The PipelineRun name to use for the working directory.
* imageName: The name to give the image after it is built, including the tag.
* context: The Docker build context
* noPush: Allows you to choose whether you want to push the image built to the given destination (dockerRegistry/imageName).
* dockerfilePath: The path to the Dockerfile needed for the build.
* buildArgs: An array used to pass any build arguments needed into the Dockerfile.

The task uses [kaniko-executor image](https://console.cloud.google.com/gcr/images/kaniko-project/GLOBAL/executor@sha256:23ae6ccaba2b0f599966dbc5ecf38aa4404f4cd799add224167eaf285696551a/details?tag=latest), from gcr.io (Google Container Registry).


### kubectl 

This task allows you to execute kubectl commands on the cluster the pipeline runs on.

Parameters: 
* command: An array of the parts of the command.

The task uses the [kubectl image](https://github.com/galasa-dev/automation/pkgs/container/kubectl).


### make-with-params

This task is used to perform the shell command 'make all' to execute a Makefile.

Parameters:
* directory: The directory to perform the command in.
* params: An array of commands, defaults to all.

This task uses the [golang image](https://github.com/orgs/galasa-dev/packages/container/package/golang).


### maven-build

This task performs a Maven build. It is generic and allows for parameters to dictate the exact type of build.

Parameters:
* context: The directory where you want the Maven build to take place (where the pom.xml file is).
* settingsLocation: The location of the settings.xml produced by the maven-gpg task. This will normally be /workspace/git/PIPELINE_RUN_NAME/REPO/gpg/settings.xml. For the OBR builds, as two Maven builds occur in two different contexts, to avoid doing maven-gpg twice, the settingsLocation is set.
* buildArgs: An array used for any additional arguments to pass to Maven.
* command: An array of commands to use in the build such as 'deploy' or 'install'.
* image: The Maven image to use for the task, defaults to Maven version 3.8.6 with the IBM Semeru Java 17.

This task uses the [Maven 3.8.6 with the IBM Semeru Java 17 image](https://github.com/orgs/galasa-dev/packages/container/package/maven) unless overridden.

### script

This task is used to perform a script.

Parameters:
* context: The directory to perform the command in.
* script: A string containing the script to be performed
* image: By default this uses busybox to contain most commands likely needed. However if other commands are needed then a custom image can be passed here.

This task, by default, uses the latest [busybox image](https://github.com/orgs/galasa-dev/packages/container/package/busybox). Unless, an image is passed as a paramter.


### tkn-cli

This task is used the Tekton CLI to communicate with Tekton.

Parameters:
* context: The directory to perform the command in.
* command: An array with the parts of the command to perform.

This task uses the custom [tkn image](https://github.com/galasa-dev/automation/pkgs/container/tkn).


## How to manually trigger a pipeline
Use the `trigger-pipeline.sh` script to trigger one of the main-line build pipelines.
The tool may not support all the pipelines yet, feel free to add ones which are missing.

For example: To kick-off the extensions pipeline...
```
./trigger-pipeline.sh --extensions
```

> Note: The pipelines kicked off are the mainline pipelines, not pull-request pipelines,
so be careful as this will cause things to be published to the public repositories.

This tool is useful if there is a glitch in the 'chain' or builds kicked off when 
something on a `main` branch builds, but fails to kick-off the next build in the 'chain'.
So you can re-start the chain of builds without resorting to submitting empty change-sets
and another pull request. 

ie: If the main builds fail and you want to re-start a build.

This can be the case if we get environmental failures, for examople when argocd fails to 
re-deploy one of the docker images from the build.

## How are the IBM build machines protected from malicious code in a fork-pull-request ?
There are built-in protections to prevent malicious code being executed as part of a build process
on the IBM build hardware. The mechanism is described [here](./docs/pull-request-build-authentication.md).


# Release Pipeline

This directory contains all scripts and pipelines and the specific instructions needed to complete a release of the open source Galasa project. See the [README](./releasePipeline/README.md) for more details.