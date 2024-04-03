# Move to new version of Galasa

These are manual steps to bump the version of Galasa to the next version.

1. Create a new branch in all of the repositories below called something like 'version-bump', don't call it 'release'

2. Upgrade Framework

    a. Create branch
    b. Invoke the `set-version --version {new version}` script.
    c. Make sure it builds with `build-locally.sh`
    d. push
    e. Open PR for this change and merge into main

    Make sure the main build this starts is complete (runs all the way to Isolated and finishes) before moving on to the next step, or the following builds will fail. **If you merge the PRs in a random order, for example, cli before Framework, the cli build will be looking for the next version of Framework, but that might not have been built yet.**

3. Upgrade Managers
   As above, using the `build-locally.sh` script.

4. Upgrade OBR

    a. Create branch
    b. Invoke the `set-version --version {new version}` script.
    c. Make sure it builds with `build-locally.sh`
    d. push
    e. Open PR for this change and merge into main

    As above, make sure the main build this starts has finished before moving on

5. Upgrade CLI

    a. Change the VERSION file
    b. Change the following line in build.gradle

    ```groovy
    def galasaFrameworkVersion = '0.30.0'
    ```

6. Upgrade Isolated

    a. full/pomDocs.xml
    b. full/pomJavaDoc.xml
    c. full/pomZip.xml
    d. mvp/pomDocs.xml

    e. mvp/pomJavaDoc.xml

    f. mvp/pomZip.xml

    g. Open PR for these changes and merge into main
