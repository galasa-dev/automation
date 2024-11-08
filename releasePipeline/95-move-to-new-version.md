# Move to new version of Galasa

These are manual steps to bump the version of Galasa to the next version.

1. Create a new branch in all of the repositories below called something like 'version-bump', don't call it 'release'

2. Upgrade the Galasa Monorepo

    a. Create branch

    b. Invoke the `set-version --version {new version}` script in each of these modules in order:

        i. Framework
        ii. Extensions
        iii. Managers
        iv. OBR

    c. Make sure it builds with `./tools/build-locally.sh --module framework --chain true` which will invoke each individual module's `build-locally.sh` script

    d. Push the changes to your branch

    e. Open PR for this change and wait for the PR build to pass

    f. Merge in the PR

    g. Upgrade the `galasaecosystem.runtime.version` CPS property with the release version value, for example: `galasactl properties set --namespace galasaecosystem --name runtime.version  --value 0.35.0 --bootstrap https://prod1-galasa-dev.cicsk8s.hursley.ibm.com/api/bootstrap`. This is needed so the 'run-tests' pipeline will pass in the next step.


3. Upgrade CLI

    a. Create branch

    b. Invoke the `set-version --version {new version}` script.

    c. Make sure it builds with `build-locally.sh`
    
    d. Push

    e. Open PR for this change and wait for the PR build to pass

    f. Merge in the PR and wait for the Main build to pass and finish

    g. When the isolated Main build is triggered, cancel it with `kubectl delete pipelinerun -n galasa-build trigger-isolated-main-xxxx` replacing the correct pipeline run name.

4. Upgrade Isolated

    a. Create branch

    b. Invoke the `set-version --version {new version}` script.

    c. Make sure it builds with `build-locally.sh`
    
    d. Push

    e. Open PR for this change, wait for the PR build to pass, then merge in the PR, and wait for the Main build to pass and finish.

5. Upgrade Helm charts

    a. Create branch

    b. Invoke the `set-version --version {new version}` script.
    
    c. Push

    e. Open PR for this change, wait for the PR build to pass, then merge in the PR, and wait for the Main build to pass and finish.
