# Galasa Automation Repository

This repository is the single location for all the automation and CI/CD that occurs in Galasa. 

Find out more about:
1. [.github](#github-actions): GitHub Actions workflows
1. [dockerfiles](#dockerfiles): The organised Dockerfiles for the images built for Galasa
1. [docs](#docs): Documentation pages and images
1. [infrastructure](#infrastructure): The Galasa infrastructure as code, including the Kubernetes set-up
1. [offline-tools](#offline-tools): Source code for the copyright checker tool
1. [releasePipeline](#release-pipeline): Scripts and instructions for a Galasa release

# GitHub-Actions

This directory contains GitHub Actions workflows. Runs of these workflows can be found in the [Actions tab](https://github.com/galasa-dev/automation/actions) of this repository.

apply-galasa-resources:
Uses `galasactl resources apply` to apply changes to the file [galasa-service-main-resources.yaml](./infrastructure/galasa-kube1/galasa-service1/galasa-service-main-resources.yaml) to galasa-service-main's CPS properties.

base-image:
Builds and pushes the Galasa base httpd image to GHCR. Should be triggered if changes are made to the [base Dockerfile](./dockerfiles/base/base.Dockerfile).

build-automation:
This workflow runs when code changes are merged into the main branch of this repository. It builds the custom Docker images whose Dockerfiles can be found in the [dockerfiles/common](./dockerfiles/common/) directory, and pushes these to GHCR. More information about these images can be found [below](#dockerfiles).

build-helm:
Uses the Helm CLI to uninstall, install and test galasa-service1.

pr-build-automation:
This workflow runs if a Pull Request is opened on this reposutory. It builds the custom Docker images whose Dockerfiles can be found in the [dockerfiles/common](./dockerfiles/common/) directory to make sure they build successfully.

regression-tests-core-non-zos:
This workflow runs daily and regression tests a selection of the Galasa Managers that do not exercise z/OS so these tests can be run on the external galasa-service-main.

run-core-test:
Runs the test CoreManagerIVT on galasa-service-main for the purpose of verifying the service health.

sync-docker-proxy:
Runs weekly to sync images stored in Galasa's [GitHub Packages](https://github.com/orgs/galasa-dev/packages) with any updates from Docker Hub.


## Release Process Workflows

release-branch-create:
Creates a new branch on a selection of repositories from a source branch.

release-branch-delete:
Deletes a branch on a selection of repositories.

release-branch-tag:
Tags a branch with a `vx.xx.x` tag on a selection of repositories.

release-central-publisher-portal:
Bundles all dev.galasa artifacts into a zip and uses the Central Publisher Portal API to publish them to the staging repository, before releasing to Maven Central.


# Dockerfiles

This directory is the single location for all Dockerfiles needed to build the images Galasa needs.

| Category | Dockerfiles |
|----------|-------------|
| Custom images (If there is not be a Docker official image that allows us to use a tool, we have created custom images to enable this. The Dockerfiles for all of the custom images are in the _dockerfiles/common_ directory) | argocd, gitcli, gpg, openapi, openjdk17ibmgradle, swagger |
| Base image (Most other images are built on top of this. Used to enable use of the Apache HTTP Server) | base |


# Infrastructure

Galasa's infrastructure is hosted on an external Kubernetes cluster, galasa-kube1:

* Galasa Service service-1 on which runs all remaining tests.
* All Deployments, Services and Ingresses which make up our Maven artifact repositories are hosted on the external cluster.
* The [ArgoCD](argocd.galasa.dev) instance which controls the above resources is hosted on the external cluster.


# Offline Tools

The offline-tools directory contains the source code for the GitHub Copyright Checker tool. Read more [here](./offline-tools/copyrighter/README.md)

_The GitHub Copyright Checker tool is currently disabled, we plan to reinstate this in the future._


# Release Pipeline

This directory contains all scripts and pipelines and the specific instructions needed to complete a release of the open source Galasa project. See the [README](./releasePipeline/README.md) for more details.
