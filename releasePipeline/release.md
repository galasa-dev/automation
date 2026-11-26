# RELEASE PROCESS

**Option 1: Automated Release Process (Recommended)**

The release process is split into two automated workflows:

### Part 1: Build and Test (Automated)

Run the [Release Process workflow](https://github.com/galasa-dev/automation/actions/workflows/release.yaml) to automate the build and test steps:

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

**All regression tests must pass before moving on to deployment.**

### Part 2: Deploy and Release (Automated)

After all tests pass, run the [Release Deployment workflow](https://github.com/galasa-dev/automation/actions/workflows/release-deployment.yaml):

> [!NOTE]
> **Semantic versioning:** Galasa follows [semantic versioning](https://semver.org/) (`major.minor.patch`). Version numbers are decided as follows:
> - **major** - incremented for incompatible API changes
> - **minor** - incremented when new functionality is added in a backwards-compatible manner
> - **patch** - incremented for backwards-compatible bug fixes
>
> When the workflow prompts for the new development version to bump to, you should bump to the **next patch release** (e.g. if the release version was `1.2.0`, enter `1.2.1`).

```bash
gh workflow run release-deployment.yaml --repo galasa-dev/automation --ref main
```

This workflow will automatically:
1. Detect the Galasa version from `galasa/build.properties`
2. Publish artifacts to Maven Central Publisher Portal
3. Poll Maven Central for artifact availability
4. Deploy Docker images to GitHub Container Registry
5. Create version tags across all repositories
6. Upload CLI and Isolated/MVP releases to GitHub
7. Trigger Homebrew and Scoop update workflows (creates PRs)
8. Bump development version (creates PRs)
9. Clean up release resources


**Manual actions required**:
1. Review and merge PRs:
   - [Homebrew tap PR](https://github.com/galasa-dev/homebrew-tap/pulls)
   - [Scoop bucket PR](https://github.com/galasa-dev/scoop-bucket/pulls)
   - [Galasa PR](https://github.com/galasa-dev/galasa/pulls)
   - [Helm PR](https://github.com/galasa-dev/helm/pulls)
   - [Web UI PR](https://github.com/galasa-dev/webui/pulls)
   - [Integratedtests PR](https://github.com/galasa-dev/integratedtests/pulls)
   - [Simplatform PR](https://github.com/galasa-dev/simplatform/pulls)
   - [Isolated PR](https://github.com/galasa-dev/isolated/pulls)
   - [Automation PR](https://github.com/galasa-dev/automation/pulls)

---

**Option 2: Manual Release Process**

If you need to run steps individually or the automated workflows fail, follow these manual steps:

### Set up

1. Clone the 'automation' repository, main branch. All the yaml and scripts you will be using can be found in the releasePipeline folder.
2. Ensure the ArgoCD CLI is installed. The argocd cli can be downloaded [here]( https://argo-cd.readthedocs.io/en/stable/cli_installation/).
3. Log into ArgoCD `argocd login --sso argocd.galasa.dev --grpc-web`
4. Ensure GitHub CLI is istalled. It can be installed using the guide [here](https://github.com/cli/cli?tab=readme-ov-file#installation)
5. Authenticate github cli using `gh auth login --web`
6. Ensure you have the latest galasabld program. It can be downloaded [here](https://development.galasa.dev/main/binary/bld/). Add it on the path.
7. jq needs to be installed. It can be downloaded [here](https://jqlang.github.io/jq/download/).
8. watch needs to be installed.

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

### Run the regression tests

**These three steps can be done at the same time:**

1. Run [23-run-isolated-tests.sh](./23-run-isolated-tests.sh).
2. Run [24-run-simbank-ivts.sh](./24-run-simbank-ivts.sh).
3. Run [25-run-ivts.sh](./25-run-ivts.sh).

**All tests must pass before moving on.**

### Deploy the Galasa artifacts to Maven Central

1. Run [30-central-publisher-portal.sh](./30-central-publisher-portal.sh) - Publishes a bundle of 'dev.galasa' artifacts to the Maven Central Publisher Portal.
2. Log into the Central Publisher Portal and publish the 'dev.galasa' artifacts by following [31-publish-to-maven-central.md](./31-publish-to-maven-central.md).
3. Run [32-wait-maven.sh](./32-wait-maven.sh) with `--version <version>` to wait for the artifacts to reach Maven Central (20-40 minutes).

### Deploy images to GitHub Container Registry

1. Run [34-deploy-docker-galasa.sh](./34-deploy-docker-galasa.sh) - Deploy the Container images to GHCR. Re-tags and uploads images. Takes over 20 mins.

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

If the workflow fails:
1. Follow manual steps in [95-move-to-new-version.md](./95-move-to-new-version.md).
2. Run [set-version.sh](./set-version.sh) to update CPS properties in [`../infrastructure/galasa-kube1/galasa-service1/galasa-service-main-resources.yaml`](../infrastructure/galasa-kube1/galasa-service1/galasa-service-main-resources.yaml).

### Clean up

1. Run [03-repo-branches-delete.sh](./03-repo-branches-delete.sh) for 'release' branches.
2. Run [03-repo-branches-delete.sh](./03-repo-branches-delete.sh) for 'prerelease' branches.
3. Run [92-delete-argocd-apps.sh](./92-delete-argocd-apps.sh).
4. Manually delete GHCR images tagged 'release' and 'prerelease'.
