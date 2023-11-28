# Move to new version of Galasa

These are manual steps to bump the version of Galasa to the next version.

1. Create a new branch in all of the repositories below called something like 'version-bump', don't call it 'release'

2. Upgrade Framework

    a. Create branch
    b. Invoke the `set-version --version {new version}` script.
    c. Make sure it builds with `build-locally.sh`
    d. push
    e. Open PR for this change and merge into main

    Make sure the main build this starts is complete (runs all the way to Isolated and finishes) before moving on to the next step, or the following builds will fail. **If you merge the PRs in a random order, for example, Eclipse before Framework, the Eclipse build will be looking for the next version of Framework, but that might not have been built yet.**

2. Upgrade Managers
   As above, using the `build-locally.sh` script.

3. Upgrade OBR

    a. Create branch
    b. Invoke the `set-version --version {new version}` script.
    c. Make sure it builds with `build-locally.sh`
    d. push
    e. Open PR for this change and merge into main

    As above, make sure the main build this starts has finished before moving on

4. Upgrade CLI

    a. Change the VERSION file
    b. Change the following line in build.gradle
    ```
    def galasaFrameworkVersion = '0.30.0'
    ```

5. Upgrade Eclipse
    These changes need to be done manually.
    For example: Look at this PR and do the same changes to the new version number... https://github.com/galasa-dev/eclipse/pull/50

    a. galasa-eclipse-parent/dev.galasa.eclipse.feature/feature.xml
    b. galasa-eclipse-parent/dev.galasa.eclipse.feature/pom.xml
    c. galasa-eclipse-parent/dev.galasa.eclipse.site/category.xml
    d. galasa-eclipse-parent/dev.galasa.eclipse.site/pom.xml
    e. galasa-eclipse-parent/dev.galasa.eclipse/META-INF/MANIFEST.MF
    f. galasa-eclipse-parent/dev.galasa.eclipse/pom.xml
    g. galasa-eclipse-parent/dev.galasa.simbank.feature/feature.xml
    h. galasa-eclipse-parent/dev.galasa.simbank.feature/pom.xml
    i. galasa-eclipse-parent/dev.galasa.simbank.ui/META-INF/MANIFEST.MF
    j. galasa-eclipse-parent/dev.galasa.simbank.ui/pom.xml
    k. galasa-eclipse-parent/dev.galasa.zos.feature/feature.xml
    l. galasa-eclipse-parent/dev.galasa.zos.feature/pom.xml
    m. galasa-eclipse-parent/dev.galasa.zos3270.ui/META-INF/MANIFEST.MF
    n. galasa-eclipse-parent/dev.galasa.zos3270.ui/pom.xml
    o. galasa-eclipse-parent/pom.xml
    p. Open PR for these changes and merge into main

    q. As above, make sure the main build this starts has finished before moving on


6. Upgrade Isolated

    a. full/pomDocs.xml
    b. full/pomJavaDoc.xml
    c. full/pomZip.xml
    d. mvp/pomDocs.xml

    e. mvp/pomJavaDoc.xml

    f. mvp/pomZip.xml

    g. Open PR for these changes and merge into main

