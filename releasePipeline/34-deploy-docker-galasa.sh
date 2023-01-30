#!/bin/bash

set -e

FROM=release

TO=x.xx.x

ibmcloud cr login




docker pull harbor.galasa.dev/galasadev/galasa-p2:$FROM 
docker pull harbor.galasa.dev/galasadev/galasa-javadoc-site:$FROM
docker pull harbor.galasa.dev/galasadev/galasa-boot-embedded-amd64:$FROM
docker pull icr.io/galasadev/galasa-resources:$FROM



docker tag harbor.galasa.dev/galasadev/galasa-p2:$FROM                      \
           icr.io/galasadev/galasa-p2-amd64:$TO

docker tag harbor.galasa.dev/galasadev/galasa-javadoc-site:$FROM                  \
           icr.io/galasadev/galasa-javadoc-amd64:$TO

docker tag harbor.galasa.dev/galasadev/galasa-boot-embedded-amd64:$FROM       \
           icr.io/galasadev/galasa-boot-embedded-amd64:$TO

docker tag icr.io/galasadev/galasa-resources:$FROM       \
           icr.io/galasadev/galasa-resources:$TO



docker tag harbor.galasa.dev/galasadev/galasa-p2:$FROM                       \
           icr.io/galasadev/galasa-p2-amd64:latest

docker tag harbor.galasa.dev/galasadev/galasa-javadoc-site:$FROM                \
           icr.io/galasadev/galasa-javadoc-amd64:latest

docker tag harbor.galasa.dev/galasadev/galasa-boot-embedded-amd64:$FROM      \
           icr.io/galasadev/galasa-boot-embedded-amd64:latest

docker tag icr.io/galasadev/galasa-resources:$FROM      \
           icr.io/galasadev/galasa-resources:latest



docker push icr.io/galasadev/galasa-p2-amd64:$TO
docker push icr.io/galasadev/galasa-javadoc-amd64:$TO
docker push icr.io/galasadev/galasa-boot-embedded-amd64:$TO
docker push icr.io/galasadev/galasa-resources:$TO



docker push icr.io/galasadev/galasa-p2-amd64:latest
docker push icr.io/galasadev/galasa-javadoc-amd64:latest
docker push icr.io/galasadev/galasa-boot-embedded-amd64:latest
docker push icr.io/galasadev/galasa-resources:latest