#!/bin/bash

set -e

FROM=release

TO=x.xx.x

ibmcloud cr login




docker pull harbor.galasa.dev/galasadev/galasa-cli-amd64:$FROM



docker tag harbor.galasa.dev/galasadev/galasa-cli-amd64:$FROM                      \
           icr.io/galasadev/galasa-cli-amd64:$TO



docker tag harbor.galasa.dev/galasadev/galasa-cli-amd64:$FROM                       \
           icr.io/galasadev/galasa-cli-amd64:latest




docker push icr.io/galasadev/galasa-cli-amd64:$TO



docker push icr.io/galasadev/galasa-cli-amd64:latest