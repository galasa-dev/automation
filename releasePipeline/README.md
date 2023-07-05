(To be updated in the projectmanagement repo also)

# How to release Galasa


## Introduction
With many repos making up the Galasa project and many different types of artifacts being produced, the build and release of Galasa has become a little complicated. These instructions detail the process of building, testing and releasing a version of Galasa and related components.

Galasa has been broken up into multiple components, and these components are only released if the component has changed. These components (and related repos) are:-

1. Galasa (wrapping, gradle, maven, framework, extensions, managers, obr, eclipse, isolated)
2. CLI (cli)

The Galasa component is always released, but the others are only cloned, built, tested and released if there are changes.


## PRE-RELEASE PROCESS

Follow the instructions in [prerelease.md](prerelease.md)

## RELEASE PROCESS

Follow the instructions in [release.md](./release.md)


