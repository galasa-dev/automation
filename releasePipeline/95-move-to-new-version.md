# Move to new version of Galasa

These are manual steps to bump the version of Galasa to the next version.

1. Create a new branch in all of the repositories below called something like 'version-bump', don't call it 'release'

2. Upgrade the Galasa Monorepo

    a. Create branch

    b. Invoke the `./tools/set-version --version {new version}` script in which invokes a separate `set-version.sh` for each module.

    c. Currently not all versions are found by the script alone such as dev.galasa.platform's version used throughout the code, so do a search for the current version in VSCode and replace with the new development version. Manually check that all dev.galasa bundles have been upgraded.

    d. Make sure it builds with `./tools/build-locally.sh` which will invoke each individual module's `build-locally.sh` script. Make sure the API Server starts locally also.

    e. Push the changes to your branch

    f. Open PR for this change and wait for the PR build to pass

    g. Merge in the PR and wait for the Main build to pass and finish

    **Note:** Once the Galasa mono repo's build finishes, this will trigger the `recycle-prod1` Tekton pipeline, which will then trigger the `run-tests` Tekton pipeline. The `run-tests` will fail as the CPS properties have not yet been upgraded to the new development version - this is okay.


3. Upgrade CLI

    a. Create branch

    b. Invoke the `set-version --version {new version}` script.

    c. Make sure it builds with `build-locally.sh`
    
    d. Push

    e. Open PR for this change and wait for the PR build to pass

    f. Merge in the PR and wait for the Main build to pass and finish

    g. When the Isolated Main build is triggered, cancel it on the GitHub UI [here](https://github.com/galasa-dev/isolated/actions/workflows/build.yaml) with the "Cancel Workflow" button, as you are going to rebuild it in the next step anyway.

4. Upgrade Isolated

    a. Create branch

    b. Invoke the `set-version --version {new version}` script. Currently not all versions are found by the script alone, so do a search for the current version in VSCode and replace with the new development version. Manually check that all dev.galasa bundles have been upgraded.

    c. There is no `build-locally.sh` script for this repo so you will have to rely on the GitHub Actions workflow to confirm it builds okay.
    
    d. Push

    e. Open PR for this change, wait for the PR build to pass, then merge in the PR, and wait for the Main build to pass and finish.

5. Upgrade Helm charts

    a. Create branch

    b. Invoke the `set-version --version {new version}` script.
    
    c. Push

    e. Open PR for this change, wait for the PR build to pass, then merge in the PR, and wait for the Main build to pass and finish.

6. Upgrade Simplatform

    a. Create branch

    b. Currently no `set-version.sh` script exists so do a search for the current version in VSCode and replace with the new development version. Manually check that all dev.galasa bundles have been upgraded then run `build-locally.sh` to check it builds.
    
    c. Push

    e. Open PR for this change, wait for the PR build to pass, then merge in the PR, and wait for the Main build to pass and finish.

7. Upgrade Web UI

    a. Create branch

    b. Invoke the `set-version --version {new version}` script.
    
    c. Push

    e. Open PR for this change, wait for the PR build to pass, then merge in the PR, and wait for the Main build to pass and finish.

8. Upgrade Integratedtests (not a released component)

    a. Create branch

    b. Currently no `set-version.sh` script exists so do a search for the current version in VSCode and replace with the new development version. Manually check that all dev.galasa bundles have been upgraded then run `build-locally.sh` to check it builds.
    
    c. Push

    e. Open PR for this change, wait for the PR build to pass, then merge in the PR, and wait for the Main build to pass and finish.