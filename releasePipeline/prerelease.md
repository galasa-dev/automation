# PRE-RELEASE PROCESS

It may be beneficial to complete a pre-release before starting a vx.xx.x release of Galasa. This is to ensure the main Galasa component builds successfully and to iron out any problems before the actual release, as there will be a freeze on delivering code during this time.

**Do not check in any changes you make to files during this work item unless you are correcting a mistake - back out everything at the end**

## Set up

1. Clone the 'automation' repository, main branch. All the yaml and scripts you will be using can be found in the releasePipeline folder.
2. Ensure the ArgoCD CLI is installed. The argocd cli can be downloaded [here]( https://argo-cd.readthedocs.io/en/stable/cli_installation/).
3. Log into ArgoCD `argocd login --sso argocd.galasa.dev --grpc-web`
4. Ensure GitHub CLI is istalled. It can be installed using the guide [here](https://github.com/cli/cli?tab=readme-ov-file#installation)
5. Authenticate github cli using `gh auth login`
6. Ensure the Tekton CLI is installed. You can download it [here](https://tekton.dev/docs/cli/).
7. Authenticate to the cicsk8s cluster using `cicsk8s sso`

## Pre-release steps - Automated

1. Ensure you have completed the [set up](#set-up) before continuing.
2. Run [01-run-pre-release.sh](./01-run-pre-release.sh). If the process fails at any stage, you can continue by re-running the script that failed from the manual steps and finish using the [manual steps below](#pre-release-steps---manual).
3. Run [20-check-artifacts-signed.sh](./20-check-artifacts-signed.sh). When prompted, choose the '`pre-release`' option.
    - Each maven artifact should contain a file called com.auth0.jwt-<*VERSION*>.jar.asc. If the .asc files aren't present, debug and diagnose why the artifacts have not been signed.

4. Run a MEND scan for the [MVP zip](https://development.galasa.dev/prerelease/maven-repo/mvp/dev/galasa/galasa-isolated-mvp) by following the instructions in the internal [Developer docs](https://github.ibm.com/galasa/developer-docs/blob/322ea364dd63ad533427c984c6c7dd4c5f8c75cc/docs/300-process/dfg-build-process.md) to check for any vulnerabilities before moving onto the release process.

## Pre-release steps - Manual

1. Ensure you have completed the [set up](#set-up) before continuing.
2. Run [02-create-argocd-apps.sh](./02-create-argocd-apps.sh). When prompted, choose the '`pre-release`' option.
3. Run [03-repo-branches-delete.sh](./03-repo-branches-delete.sh). When prompted, choose the '`pre-release`' option.
This script kicks off a pipeline to delete all branches called `prerelease` in all the github repositories, so we know they are clean.
4. Run [04-repo-branches-create.sh](./04-repo-branches-create.sh).  When prompted, choose the '`pre-release`' option.  This script creates
a new branch called `prerelease` in every github repo we need to build. **Note:** Creating this branch in the 'Helm' repository is all that is required to trigger the GitHub Actions workflow that packages and releases a new Tag and Release of the Helm charts. As this is a prerelease, they will need to be deleted after.
5. Run [05-helm-charts.sh](./05-helm-charts.sh). When prompted, choose the '`pre-release`' option. This script uses the GitHub API to check that all Helm charts that had changes in this release have a new Release and Tag object on GitHub.
6. Delete all Releases and Tags for the Helm charts that were just created by pushing to the `prerelease` branch.
    1. Delete all Releases that were created: [Releases](https://github.com/galasa-dev/helm/releases) - Next to a Release, click the Delete icon and 'Delete this release'.
    2. Delete all Tags that were created: [Tags](https://github.com/galasa-dev/helm/tags) - Next to a Tag, click the three dots, then 'Delete Tag' then 'Delete this Tag'.
7. Begin the build of Galasa by starting the Galasa mono repo release build. Run [10-build-galasa-mono-repo.sh](./10-build-galasa-mono-repo.sh). When prompted, choose the '`pre-release`' option. This script uses the GitHub CLI to start the [Release Build Orchestrator](https://github.com/galasa-dev/galasa/actions/workflows/releases.yaml). You will have to monitor the workflow run and ensure it finishes successfully.
8. The build of the Isolated repository will be triggered automatically as part of the build chain, so monitor this build and make sure it finishes successfully. 
    - Watch the [Isolated Main build workflow](https://github.com/galasa-dev/isolated/actions/workflows/build.yaml) for the `prerelease` ref back in GitHub
9. Now run the Web UI Main build. Run [11-build-webui.sh](./11-build-webui.sh). When prompted, choose the '`pre-release`' option. This script uses the GitHub CLI to start the [Main build](https://github.com/galasa-dev/webui/actions/workflows/build.yaml). You will have to monitor the workflow run and ensure it finishes successfully.
10. Run [20-check-artifacts-signed.sh](./20-check-artifacts-signed.sh). When prompted, choose the '`pre-release`' option.
    - This will search and check that one artifact from each Galasa module (platform, wrapping, gradle, maven, framework, extensions, managers and obr) contains a file called *.jar.asc which shows the artifacts have been signed. If the .asc files aren't present, debug and diagnose why the artifacts have not been signed.
11. Run a MEND scan for the [MVP zip](https://development.galasa.dev/prerelease/maven-repo/mvp/dev/galasa/galasa-isolated-mvp) by following the instructions in the internal [Developer docs](https://github.ibm.com/galasa/developer-docs/blob/322ea364dd63ad533427c984c6c7dd4c5f8c75cc/docs/300-process/dfg-build-process.md) to check for any vulnerabilities before moving onto the release process.
12. **Note:** A [story](https://github.com/galasa-dev/projectmanagement/issues/2108) exists to automate this manual process for future releases. Test the [MVP zip](https://development.galasa.dev/prerelease/maven-repo/mvp/dev/galasa/galasa-isolated-mvp) by working through the instructions on the Galasa website to do with using Galasa offline (although you will need to slightly adapt in some places as you are testing the MVP from the prerelease maven repo - these differences are documented below):
    - https://galasa.dev/docs/cli-command-reference/installing-offline
        - 1: The output of `docker load -i isolated.tar` should instead be `Loaded image: ghcr.io/galasa-dev/galasa-mvp:main`.
        - 2: Run the container by running `docker run -d -p 8080:80 --name galasa ghcr.io/galasa-dev/galasa-mvp:main` instead.
    - https://galasa.dev/docs/running-simbank-tests/simbank-cli-offline
        - After starting the Simplatform application by running the `run-simplatform.sh` script, you can start your 3270 emulator pointing it to port 2023 of localhost by running `c3270 localhost -port 2023` (you will need the x3270 tool installed).
    - https://galasa.dev/docs/running-simbank-tests/running-simbank-tests-cli-offline
        - To run the Simbank tests using the galasactl binary and using only the Maven artifacts provided within the zip, you can run the below commands from the top level of the zip:
            - `./galasactl/galasactl runs submit local --log - --obr mvn:dev.galasa/dev.galasa.simbank.obr/<VERSION>/obr --localMaven file:////Users/<YOURUSER>/Downloads/galasa-isolated-mvp-<VERSION>/maven --class dev.galasa.simbank.tests/dev.galasa.simbank.tests.SimBankIVT`
            - `./galasactl/galasactl runs submit local --log - --obr mvn:dev.galasa/dev.galasa.simbank.obr/<VERSION>/obr --localMaven file:////Users/<YOURUSER>/Downloads/galasa-isolated-mvp-<VERSION>/maven --class dev.galasa.simbank.tests/dev.galasa.simbank.tests.BasicAccountCreditTest`
            - `./galasactl/galasactl runs submit local --log - --obr mvn:dev.galasa/dev.galasa.simbank.obr/<VERSION>/obr --localMaven file:////Users/<YOURUSER>/Downloads/galasa-isolated-mvp-<VERSION>/maven --class dev.galasa.simbank.tests/dev.galasa.simbank.tests.ProvisionedAccountCreditTests`
            - `./galasactl/galasactl runs submit local --log - --obr mvn:dev.galasa/dev.galasa.simbank.obr/<VERSION>/obr --localMaven file:////Users/<YOURUSER>/Downloads/galasa-isolated-mvp-<VERSION>/maven --class dev.galasa.simbank.tests/dev.galasa.simbank.tests.BatchAccountsOpenTest`
