# RELEASE PROCESS

## Set up

1. Clone the 'automation' repository, main branch. All the yaml and scripts you will be using can be found in the releasePipeline folder.
2. Ensure argocd is installed. The argocd cli can be downloaded [here]( https://argo-cd.readthedocs.io/en/stable/cli_installation/).
3. Log into ArgoCD `argocd login --sso argocd.galasa.dev`
4. You will need to log into both the internal cicsk8s and external ibmcloud Kubernetes clusters.
5. Ensure you have the latest galasabld program. It can be downloaded [here](https://development.galasa.dev/main/binary/bld/). Add it on the path.
6. jq needs to be installed. It can be downloaded [here](https://jqlang.github.io/jq/download/).
7. watch needs to be installed.
8. IBM Cloud CLI needs to be installed and logged in:
```
ibmcloud login --sso
ibmcloud cr region-set global
```

For each of the Kubernetes Tekton command, you can follow with tkn -n galasa-build pr logs -f --last to watch it's progress. Only move onto the next command once the previous is completed successfully.

## Release steps

1. Ensure you have completed the [set up](#set-up) before continuing.
2. Run [02-create-argocd-apps.sh](./02-create-argocd-apps.sh). When prompted, choose the '`release`' option.
3. Run [03-repo-branches-delete.sh](./03-repo-branches-delete.sh). When prompted, choose the '`release`' option.  
4. Run [04-repo-branches-create.sh](./04-repo-branches-create.sh).  When prompted, choose the '`release`' option. 

5. Run [20-build-all-code..sh](./20-build-all-code.sh). When prompted, choose the '`release`' option.
6. Run [28-run-regression-tests.sh](./28-run-regression-tests.sh). 


All the tests must pass before moving on.