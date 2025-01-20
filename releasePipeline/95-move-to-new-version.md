# Move to new version of Galasa

These are manual steps to bump the version of Galasa to the next version.

1. Create a new branch in all of the repositories below called something like 'version-bump' (don't call it 'release').

2. Upgrade [Galasa](https://github.com/galasa-dev/galasa)

    a. Invoke the `./tools/set-version --version {new version}` script in which invokes a separate `set-version.sh` for each module.

    b. Run the `./tools/build-locally.sh`, which will invoke each individual module's `build-locally.sh` script, which will update the versions in the generated `release.yaml`s.

    c. Manually check that all dev.galasa bundles have been upgraded. Do a search for the current version in VSCode to check for any versions that did not get uplifted by the script, and replace with the new development version.

    d. Make sure the API Server starts locally.

    e. Push the changes to your branch, open a PR, wait for the PR build to pass, then merge in the PR, and wait for the Main build to pass and finish.

    **Note:** Once the Galasa mono repo's build finishes, this will trigger the `recycle-prod1` Tekton pipeline, which will then trigger the `run-tests` Tekton pipeline. The `run-tests` will fail as the CPS properties have not yet been upgraded to the new development version (unless you have already done it with galasactl) - this is okay.

3. Upgrade [Helm](https://github.com/galasa-dev/helm)

    a. Invoke the `set-version --version {new version}` script.
    
    b. Push the changes to your branch, open a PR, wait for the PR build to pass, then merge in the PR, and wait for the Main build to pass and finish.

4. Upgrade [Simplatform](https://github.com/galasa-dev/simplatform)

    a. Invoke the `set-version --version {new version}` script. **Note:** This will fail if the Galasa OBR has not been fully rebuilt and redeployed yet to the development.galasa.dev site, as the `set-version.sh` script uses `mvn` to uplift the versions, which will look for Simplatform's dependencies at the new version in Maven Central then the development.galasa.dev site.
    
    b. Push the changes to your branch, open a PR, wait for the PR build to pass, then merge in the PR, and wait for the Main build to pass and finish.

5. Upgrade [Web UI](https://github.com/galasa-dev/webui)

    a. Invoke the `set-version --version {new version}` script.
    
    b. Push the changes to your branch, open a PR, wait for the PR build to pass, then merge in the PR, and wait for the Main build to pass and finish.

6. Upgrade [Integratedtests](https://github.com/galasa-dev/integratedtests) (not a released component)

    a. Currently no `set-version.sh` script exists so do a search for the current version in VSCode and replace with the new development version. **Note:** A [story](https://github.com/galasa-dev/projectmanagement/issues/2107) is open to create a set-version script so this should be updated when that is complete. Manually check that all dev.galasa bundles have been upgraded then run `build-locally.sh` to check it builds.
    
    b. Push the changes to your branch, open a PR, wait for the PR build to pass, then merge in the PR, and wait for the Main build to pass and finish.

7. Upgrade the [internal integrated tests](https://github.ibm.com/galasa/internal-integratedtests) (not a released component)

    a. Currently no `set-version.sh` script exists so do a search for the current version in VSCode and replace with the new development version. **Note:** A [story](https://github.com/galasa-dev/projectmanagement/issues/2107) is open to create a set-version script so this should be updated when that is complete. 
    
    b. Push the changes to your branch, open a PR, then merge in the PR, and wait for the Main build to pass and finish.

8. Upgrade [CLI](https://github.com/galasa-dev/cli)

    a. Invoke the `set-version --version {new version}` script.

    b. Make sure it builds with `build-locally.sh`. This will also uplift the version in the generated docs files.

    c. Push the changes to your branch, open a PR, wait for the PR build to pass, then merge in the PR, and wait for the Main build to pass and finish.

    d. When the Isolated Main build is triggered, cancel it on the GitHub UI [here](https://github.com/galasa-dev/isolated/actions/workflows/build.yaml) with the "Cancel Workflow" button, as you are going to rebuild it in the next step anyway.

9. Upgrade [Isolated](https://github.com/galasa-dev/isolated)

    a. Invoke the `set-version --version {new version}` script.

    b. Make sure it builds with the `build-locally.sh`.
    
    c. Push the changes to your branch, open a PR, wait for the PR build to pass, then merge in the PR, and wait for the Main build to pass and finish.