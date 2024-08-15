# Move to new version of Galasa

These are manual steps to bump the version of Galasa to the next version.

1. Create a new branch in all of the repositories below called something like 'version-bump', don't call it 'release'

2. Upgrade Framework

    a. Create branch

    b. Invoke the `set-version --version {new version}` script.

    c. Make sure it builds with `build-locally.sh`

    d. Push

    e. Open PR for this change and wait for the PR build to pass

    f. Merge in the PR and wait for the Main build to pass and finish

    g. When the extensions Main build is triggered, cancel it with `kubectl delete pipelinerun -n galasa-build trigger-extensions-main-xxxx` replacing the correct pipeline run name.

    This is because we will be building the extensions at Main after the next step, so no point wasting time for duplicate builds.

3. Upgrade Extensions

    a. Create branch

    b. Invoke the `set-version --version {new version}` script.

    c. Make sure it builds with `build-locally.sh`
    
    d. Push

    e. Open PR for this change and wait for the PR build to pass

    f. Merge in the PR and wait for the Main build to pass and finish

    g. When the managers Main build is triggered, cancel it with `kubectl delete pipelinerun -n galasa-build trigger-managers-main-xxxx` replacing the correct pipeline run name.

4. Upgrade Managers
   
   a. Create branch

    b. Invoke the `set-version --version {new version}` script.

    c. Make sure it builds with `build-locally.sh`
    
    d. Push

    e. Open PR for this change and wait for the PR build to pass

    f. Merge in the PR and wait for the Main build to pass and finish

    g. When the OBR Main build is triggered, cancel it with `kubectl delete pipelinerun -n galasa-build trigger-obr-main-xxxx` replacing the correct pipeline run name.

5. Upgrade OBR

    a. Create branch

    b. Invoke the `set-version --version {new version}` script.

    c. Make sure it builds with `build-locally.sh`
    
    d. Push

    e. Open PR for this change and wait for the PR build to pass

    f. Merge in the PR and wait for the Main build to pass and finish

    g. Upgrade the `galasaecosystem.runtime.version` CPS property with the release version value, for example: `galasactl properties set --namespace galasaecosystem --name runtime.version  --value 0.35.0 --bootstrap https://prod1-galasa-dev.cicsk8s.hursley.ibm.com/api/bootstrap`. This is needed so the 'run-tests' pipeline will pass in the next step.

    h. When the CLI Main build is triggered eventually down the build chain, cancel it with `kubectl delete pipelinerun -n galasa-build trigger-cli-main-xxxx` replacing the correct pipeline run name.

6. Upgrade CLI

    a. Create branch

    b. Invoke the `set-version --version {new version}` script.

    c. Make sure it builds with `build-locally.sh`
    
    d. Push

    e. Open PR for this change and wait for the PR build to pass

    f. Merge in the PR and wait for the Main build to pass and finish

    g. When the isolated Main build is triggered, cancel it with `kubectl delete pipelinerun -n galasa-build trigger-isolated-main-xxxx` replacing the correct pipeline run name.

7. Upgrade Isolated

    a. Create branch

    b. Invoke the `set-version --version {new version}` script.

    c. Make sure it builds with `build-locally.sh`
    
    d. Push

    e. Open PR for this change, wait for the PR build to pass, then merge in the PR, and wait for the Main build to pass and finish.

8. Upgrade Helm charts

    a. Create branch

    b. Invoke the `set-version --version {new version}` script.
    
    c. Push

    e. Open PR for this change, wait for the PR build to pass, then merge in the PR, and wait for the Main build to pass and finish.
