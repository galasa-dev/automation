(To be updated in the projectmanagement repo also)

# How to release Galasa


## Introduction
With many repos making up the Galasa project and many different types of artifacts being produced, the build and release of Galasa has become a little complicated. These instructions detail the process of building, testing and releasing a version of Galasa and related components.

Galasa has been broken up into multiple components, and these components are only released if the component has changed. These components (and related repos) are:-

Galasa (gradle, maven, framework, extensions, managers, obr, eclipse, isolated, docker)
CLI (cli)
Docker Operator (docker-operator)
Kubernetes Operator (kubernetes-operator)
The Galasa component is always released, but the others are only cloned, built, tested and released if there are changes.


## Set up

1. Clone the 'automation' repository, main branch. All the yaml and scripts you will be using can be found in the releasePipeline folder.
1. Log into ArgoCD `argocd login --sso argocd.galasa.dev`
1. Log into both the internal cicsk8s and external ibmcloud Kubernetes clusters.
1. Ensure you have the latest galasabld program from https://development.galasa.dev/prod/binary/bld/ and it is on the path.
1. jq needs to be installed.
1. watch needs to be installed.
6. IBM Cloud CLI needs to be installed and logged in:
```
ibmcloud login --sso
ibmcloud cr region-set global
```

For each of the Kubernetes Tekton command, you can follow with tkn -n galasa-release pr logs -f --last to watch it's progress. Only move onto the next command once the previous is completed successfully.


## Release process

### Create branch and ArgoCD applications

1. Switch to the ibmcloud cluster.
1. 01-create-namespace.sh - Creates the galasa-release namespace in Kubernetes and applies necessary Secrets.
1. 02-create-argocd-apps.sh - Create the Deployments and Tekton resources in Kubernetes.
1. 03-create-argocd-cli-app.sh - **Only if CLI being released** - Create the Deployments in Kubernetes.
1. Switch to the cicsk8s cluster.
1. CREATE NAMESPACE HERE
1. Run `kubectl -n galasa-release create -f 10-clone-galasa.yaml` - Clone all the repos' main branches to release branches.
1. Run `kubectl -n galasa-release create -f 11-clone-cli.yaml` - **Only if CLI being released** - Clone the repo's main branch to release branch.
<!-- 1. Run `kubectl -n galasa-release create -f 12-clone-docker-operator.yaml` - **Only if Docker Operator being released** - Clone the repo's main branch to release branch.
1. Run `kubectl -n galasa-release create -f 13-clone-kubernetes-operator.yaml` - **Only if Kubernetes Operator being released** - Clone the repo's main branch to release branch. -->

### Build the components

1. Run `kubectl -n galasa-release create -f 20-build-galasa.yaml` - Build the Galasa main component.
1. Run `kubectl -n galasa-release create -f 21-build-cli.yaml` - **Only if CLI being released** - Build the CLI.
<!-- 1. Run `kubectl -n galasa-release create -f 22-build-docker-operator.yaml` - **Only if Docker Operator being released** - Build the Docker Operator.
1. Run `kubectl -n galasa-release create -f 23-build-kubernetes-operator.yaml` - **Only if Kubernetes Operator being released** - Build the Kubernetes Operator. -->

### Regression test

1. Amend 29-regression-test-galasa.yaml - Set the correct version, the bootVersion is unlikely to change.
1. Run `kubectl -n galasa-release create -f 29-regression-test-galasa.yaml` - Test Galasa.
CHANGE TO GALASACTL COMMAND?
1. Manually install and test the SimBank example in Eclipse.

All the tests must past, reruns need to be managed manually at the moment.

### Obtain release approval

1. Ask the Team and Product managers for release approval.

### Deployment

1. Amend 30-deploy-maven-galasa.yaml and amend the version parameter to the release.
1. Run `kubectl -n galasa-release create -f 30-deploy-maven-galasa.yaml` - Deploy the maven artifacts to OSS Sonatype.
1. 31-oss-sonatype-actions.md - Do the Sonatype actions detailed in this document.
1. 32-wait-maven.sh - Run the watch command to wait for the artifacts to reach Maven Central. The release will appear in the BOM metadata.
1. Wait until Maven Central is updated.
1. Amend 33-resources-image.yaml - Set the version.
1. Run `kubectl -n galasa-release create -f 33-resources-image.yaml` - Build the resources-image.
1. Amend 34-deploy-docker-galasa.sh - Set the version.
1. 34-deploy-docker-galasa.sh - Deploy the Container images to ICR.
1. Amend 35-deploy-docker-cli.sh - **Only if CLI being released** - Set the version.
1. 35-deploy-docker-cli.sh- **Only if CLI being released** - Deploy the CLI images to ICR.
<!-- 1. Amend 36-deploy-docker-docker-operator.sh - **Only if Docker Operator being released** - Set the version.
1. 36-deploy-docker-docker-operator.sh - **Only if Docker Operator being released** - Deploy the Docker Operator images to ICR.
1. Amend 37-deploy-docker-kubernetes-operator.sh - **Only if Kubernetes Operator being released** - Set the version.
1. 37-deploy-docker-kubernetes-operator.sh - **Only if Kubernetes Operator being released** - Deploy the Kubernetes Operator images to ICR. -->

### Update reference sites

1. 40-argocd-ibmcloud.md - Follow the instructions to update the IBM Cloud Galasa external sites.
1. 41-eclipse-marketplace.md - Follow the instructions to update the Eclipse Marketplace to advertise the latest Eclipse plugin.

### Tag release and deploy CLI

1. Amend 50-tag-galasa.yaml - Update the tag name, must be prefixed with lowercase v.
1. Run `kubectl -n galasa-release create -f 50-tag-galasa.yaml` - Tag the release on ALL repos.
1. 52-deploy-cli-release.md - **Only if CLI being released** - Follow instructions to deploy the CLI to the repo release.

### Clean up

1. Run `kubectl -n galasa-release create -f 90-delete-all-branches.yaml` - Delete the release branch in ALL repos.
1. 92-delete-argocd-apps.sh - Remove the ArgoCD applications, and therefore the Kubernetes resources.
1. Do for both namespaces: 93-delete-namespace.sh - Delete the galasa-release namespace in both Kubernetes clusters.

### Bump to new version

1. Create a new Issue to cover the version bump and the appropriate branch development environment.
1. 99-move-to-new-version.md - Change the repos and files as listed in this file.
1. Run a complete build to verify everything looks ok.
1. Raise PRs to push the version changes. Due to the nature of Galasa build, later PRs will fail until the previous PRs are pushed and built.




TO DO:

01 - Change secret names
02 - Update according to new structure
03 - Create CLI main app in ArgoCD to check we can create release version
10 - Create clone-galasa pipeline
11 - Create clone-cli pipeline
20 - Update complete- PRun to make sure correct
21 - Update cli build PRun to make sure correct
29 - Update regression test values
30 - Find out what this is for and update accordingly
31 - Get sonatype login and check if still relevant
32 - N/A
33 - Find out what resources image is
<!-- 34 - Update container registry and image names -->
<!-- 35 - Same as above -->
<!-- 40 - N/A -->
41 - Get Eclipse marketplace login
50 - Investigate what this does
52 - See if this is still correct
90 - Create delete pipeline
92 - N/A
93 - Get permission to delete namespace
