# Using the Helm chart to install Harbor

## Set some environment variables


## Log into the cloud account, make sure you are referring to the harbor namespace
You can do this using the VScode extension.

## Use the env variables to install helm
The `install-harbor-using-helm.sh` script will do the following:
- checkout the helm chart from github
- over-lay a few files with changed variants of those files
  - using the `.template` files in this folder.
  - The actual changes: Some mods in the init container commands in the redis and db deployments, so that the permissions of the mounted folders are set the the correct user id owner. Otherwise you get failures to read/write from the mounted location.
- take the `values.yaml.template` and copy it into a temporary folder, while substituting environment variables into the file.
  - this makes sure that any secret values are never checked-in.
- removes the existing helm install, if there is one.
  - this may take a while, as the redis pod takes nearly 1 minute to shut down.
  - all date is removed, PV claims are removed, it's totally gone after this point.
- tells helm to install harbor using the customised chart and values file.


## Post-install steps

Use `watch kubectl get pods` to monitor the pod status.

Wait for 4 minutes, until all the pods are running, and no longer showing Error or CrashLoopBackoff.
(The harbor helm chart is poor in that it just starts all pods with no sense of the order they need to start up in)
The pods are all waiting for the db pod to start, and migrate all the data to the latest schema.

Once harbor is installed, it should respond to admin login requests OK.
id: admin. The password is found in the secret in the harbor namespace.

Log in as admin. The password is available in a secret harbor-core, which is a secret config-map. In the HARBOR_ADMIN_PASSWORD record.
(It's also been echoed out when you ran the install script)

In the settings, configure harbor to use oidc as the authentication mechanism, so that it points to the dex server installed within argocd.
This is long-winded because:
- github doesn't support oidc, only oauth2 (which is the better/later standard).
- dex supports oidc, so we can use that
- argocd has a dex server in-built already, so we don't want to duplicate the argocd install.

In the settings, in authentication, select `oidc`
Then fill-in the form:
- oidc provider : dex
- oidc endpoint: https://argocd.galasa.dev/api/dex
- oicd client id: harbor
- oidc client secret : (found from the argocd secret `argocd-secret`, in  the `dex.harbor.client.secret` field)
- oidc scope: openid
- verify certificate : tick/true
- automatic oboarding: tick/true

test the connection and save it.

Log out as admin, log in as yourself. Should work.

Log out as yourself, log back in as admin.
In settings->Users select yourself, and assign yourself admin rights.

Log out as admin, log back in as you.

You should be all set.