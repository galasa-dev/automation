# Move to new version of Galasa

These are manual steps:

1. Create new branch for an issue, dont use release
2. clone framework
    a. galasa-parent/dev.galasa.framework/build.gradle - bump framework to next version
    b. release.yaml - bump framework to next version
3. clone obr
    a. release.yaml - bump overall release version
4. clone eclipse
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
5. Clone isolated
    a. full/pomDocs.xml
    b. full/pomJavaDoc.xml
    c. full/pomZip.xml
    d. mvp/pomDocs.xml
    e. mvp/pomJavaDoc.xml
    f. mvp/pomZip.xml