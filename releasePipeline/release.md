# RELEASE PROCESS

## Set up

1. Clone the 'automation' repository, main branch. All the yaml and scripts you will be using can be found in the releasePipeline folder.
2. Ensure the ArgoCD CLI is installed. The argocd cli can be downloaded [here]( https://argo-cd.readthedocs.io/en/stable/cli_installation/).
3. Log into ArgoCD `argocd login --sso argocd.galasa.dev --grpc-web`
4. Ensure GitHub CLI is istalled. It can be installed using the guide [here](https://github.com/cli/cli?tab=readme-ov-file#installation)
5. Authenticate github cli using `gh auth login --web`
6. You will need to log into both the internal cicsk8s and external ibmcloud Kubernetes clusters.
7. Ensure you have the latest galasabld program. It can be downloaded [here](https://development.galasa.dev/main/binary/bld/). Add it on the path.
8. jq needs to be installed. It can be downloaded [here](https://jqlang.github.io/jq/download/).
9. watch needs to be installed.
10. The ibmcloud CLI container registry service needs to be configured to the global region:

``` shell
ibmcloud cr region-set global
```

## Release steps

**Option 1: Automated Release Process (Recommended)**

The release process is split into two automated workflows:

### Part 1: Build and Test (Automated)

Run the [Release Process workflow](https://github.com/galasa-dev/automation/actions/workflows/release.yaml) to automate steps 1-10:

```bash
gh workflow run release.yaml --repo galasa-dev/automation --ref main
```

This workflow will automatically:
1. Set up ArgoCD apps and GitHub branches
2. Check Helm charts were released
3. Build Galasa mono repo
4. Wait for Isolated and Web UI builds
5. Check artifacts are signed
6. Test the MVP zip
7. Run GitHub Actions regression tests in parallel (Isolated, Simbank IVTs, Core IVTs)

Monitor the workflow run at: https://github.com/galasa-dev/automation/actions/workflows/release.yaml

### Part 2: Manual Steps

After the automated workflow completes:

#### MEND scan

1. Follow instructions from the internal [developer-docs wiki](https://github.ibm.com/galasa/developer-docs/wiki/how-to-mend-scan-galasa-mvp).

#### Tekton regression tests

Each of these scripts starts a Tekton pipeline on our internal cluster. This is because these tests require mainframe resource which we don't currently have available externally. These test suites run tests either locally on the Tekton runner, or submit tests to run from Tekton to prod1.

The script will give you the pipeline run name. You will have to monitor the pipeline run in Tekton and ensure it finishes successfully and all tests pass.

**These three steps should be done one after the other.**

<!-- Temporarily removing this step as these tests require a DSE CICS Region which is currently down, so these will always fail -->
<!-- 1. Run [26-run-cicsts-isolated-tests.sh](./26-run-cicsts-isolated-tests.sh). This tests that the CICS, CEMT, CEDA and SDV Managers work offline using just the Isolated zip. -->
1. Run [27-run-prod1-ivts.sh](./27-run-prod1-ivts.sh). This tests that the CICS, CEMT, CEDA, SDV and z/OS Managers work online.
2. Run [28-run-prod1-integration-tests.sh](./28-run-prod1-integration-tests.sh).

Some tests may fail on the first run due to the lack of system resource availability. Rerunning the test should hopefully result in a pass. Make sure that external systems the tests connect to are active and healthy (for example, @hobbit1983's CICS Region).

For any tests which fail, run them again individually:

   b. Amend [29-regression-reruns.yaml](./29-regression-reruns.yaml) to supply the correct version and [regression-reruns.yaml](./argocd-synced/pipelines/regression-reruns.yaml). Add the tests that failed as shown in the example, to run them again.

   c. Run `kubectl apply -f argocd-synced/pipelines/regression-reruns.yaml` and `kubectl -n galasa-build create -f 29-regression-reruns.yaml`.

   d. Repeat as required.

**All Tekton tests must pass before moving on to deployment.**

### Part 3: Deploy and Release (Automated)

After all tests pass, run the [Release Deployment workflow](https://github.com/galasa-dev/automation/actions/workflows/release-deployment.yaml):

```bash
gh workflow run release-deployment.yaml --repo galasa-dev/automation --ref main
```

This workflow will automatically:
1. Detect the Galasa version from `galasa/build.properties`
2. Publish artifacts to Maven Central Publisher Portal
3. **PAUSE for manual approval** - You must log into the Portal and click "Publish"
4. Poll Maven Central for artifact availability
5. Deploy Docker images to IBM Cloud Container Registry
6. Create version tags across all repositories
7. Upload CLI and Isolated/MVP releases to GitHub
8. Trigger Homebrew and Scoop update workflows (creates PRs)
9. Bump development version
10. Clean up release resources


**Manual actions required**:
1. Approve Maven Central publication in Portal UI - see [31-publish-to-maven-central.md](./31-publish-to-maven-central.md)
2. Review and merge Homebrew/Scoop PRs:
   - [Homebrew tap PR](https://github.com/galasa-dev/homebrew-tap/pulls)
   - [Scoop bucket PR](https://github.com/galasa-dev/scoop-bucket/pulls)

---

**Option 2: Manual Release Process**

If you need to run steps individually or the automated workflows fail, follow these manual steps:

### Set up the ArgoCD apps and GitHub branches for the release

1. Ensure you have completed the [set up](#set-up) before continuing.
2. Run [02-create-argocd-apps.sh](./02-create-argocd-apps.sh). When prompted, choose the '`release`' option.
3. Run [03-repo-branches-delete.sh](./03-repo-branches-delete.sh). When prompted, choose the '`release`' option.
4. Run [04-repo-branches-create.sh](./04-repo-branches-create.sh). When prompted, choose the '`release`' option. **Note:** Creating this branch in the 'Helm' repository triggers the workflow that packages and releases Helm charts.

### Check the Helm charts were released

1. Run [05-helm-charts.sh](./05-helm-charts.sh). When prompted, choose the '`release`' option.

### Build Galasa

1. Run [10-build-galasa-mono-repo.sh](./10-build-galasa-mono-repo.sh). When prompted, choose the '`release`' option.
2. Monitor the [Isolated Main build workflow](https://github.com/galasa-dev/isolated/actions/workflows/build.yaml) for the `release` ref.
3. Monitor the [Web UI Main build workflow](https://github.com/galasa-dev/webui/actions/workflows/build.yaml) for the `release` ref.

### Check the built artifacts are signed

1. Run [20-check-artifacts-signed.sh](./20-check-artifacts-signed.sh). When prompted, choose the '`release`' option.

### Test the MVP zip

```bash
./test-mvp-zip.sh --release
```

### MEND scan

1. Follow instructions from the internal [developer-docs wiki](https://github.ibm.com/galasa/developer-docs/wiki/how-to-mend-scan-galasa-mvp).

### Run the regression tests

#### GitHub Actions regression tests

**These three steps can be done at the same time:**

1. Run [23-run-isolated-tests.sh](./23-run-isolated-tests.sh).
2. Run [24-run-simbank-ivts.sh](./24-run-simbank-ivts.sh).
3. Run [25-run-ivts.sh](./25-run-ivts.sh).

#### Tekton regression tests

**These steps should be done one after the other:**

**All tests must pass before moving on.**

### Deploy the Galasa artifacts to Maven Central

1. Run [30-central-publisher-portal.sh](./30-central-publisher-portal.sh) - Publishes a bundle of 'dev.galasa' artifacts to the Maven Central Publisher Portal.
2. Log into the Central Publisher Portal and publish the 'dev.galasa' artifacts by following [31-publish-to-maven-central.md](./31-publish-to-maven-central.md).
3. Run [32-wait-maven.sh](./32-wait-maven.sh) with `--version <version>` to wait for the artifacts to reach Maven Central (20-40 minutes).

### Deploy images to IBM Cloud Container Registry

1. Run [34-deploy-docker-galasa.sh](./34-deploy-docker-galasa.sh) - Deploy the Container images to ICR. Re-tags and uploads images. Takes over 20 mins.

### Create version tag from release branch

1. Ensure the 'release' branch on the galasa-docs-preview repository is up to date with 'main'.
2. Publish the Galasa docs preview to production: [Publish site to production workflow](https://github.com/galasa-dev/galasa-docs-preview/actions/workflows/publish.yaml).
3. Ensure the 'release' branch on the galasa-docs repository is up to date with 'main'.
4. Run [41-tag-github-repositories.sh](./41-tag-github-repositories.sh) - Creates version tags from all release branches.

### Upload built artefacts as new Releases on GitHub

1. Follow [42-upload-cli-release.md](./42-upload-cli-release.md) to upload CLI binaries, OR trigger the [CLI release workflow](https://github.com/galasa-dev/galasa/actions/workflows/release-cli.yaml).
2. Follow [43-upload-isolated-release.md](./43-upload-isolated-release.md) to upload Isolated/MVP zips, OR trigger the [Isolated release workflow](https://github.com/galasa-dev/isolated/actions/workflows/release.yaml).

### Update Homebrew and Scoop installers for the CLI

1. Trigger the [Homebrew tap release workflow](https://github.com/galasa-dev/homebrew-tap/actions/workflows/release.yaml) - Creates a PR with the new version.
2. Trigger the [Scoop bucket release workflow](https://github.com/galasa-dev/scoop-bucket/actions/workflows/release.yaml) - Creates a PR with the new version.
3. Review and merge both PRs.

### Bump to new version for development

1. Run the [Bump Development Version workflow](https://github.com/galasa-dev/automation/actions/workflows/bump-development-version.yaml).
2. Update CPS properties for internal integrated tests using galasactl:
   - framework.test.stream.internal-inttests.location
   - framework.test.stream.internal-inttests.obr

If the workflow fails:
1. Follow manual steps in [95-move-to-new-version.md](./95-move-to-new-version.md).
2. Run [set-version.sh](./set-version.sh) to update CPS properties in [`../infrastructure/cicsk8s/galasa-dev/cps-properties.yaml`](../infrastructure/cicsk8s/galasa-dev/cps-properties.yaml).
3. Upgrade CLI stable image:

```shell
docker pull ghcr.io/galasa-dev/galasactl-ibm-x86_64:release
docker image tag ghcr.io/galasa-dev/galasactl-ibm-x86_64:release ghcr.io/galasa-dev/galasactl-ibm-x86_64:stable
docker image push ghcr.io/galasa-dev/galasactl-ibm-x86_64:stable
```

### Clean up

1. Run [03-repo-branches-delete.sh](./03-repo-branches-delete.sh) for 'release' branches.
2. Run [03-repo-branches-delete.sh](./03-repo-branches-delete.sh) for 'prerelease' branches.
3. Run [92-delete-argocd-apps.sh](./92-delete-argocd-apps.sh).
4. Manually delete GHCR images tagged 'release' and 'prerelease'.
