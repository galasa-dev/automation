# Migration notes

The secret.api.key allows the secrets manager in this namespace to contact the secret service
on the CIO account. It is copied from the argocd namespace.

The external URL to harbor is https://harbor.galasa-plan-b-lon02-3fdc13787e8248a7d32fa4e5af5b0294-0000.eu-gb.containers.appdomain.cloud

- Set that into EXT_ENDPOINT in harbor.yaml
- Set that into serviceUrl in secrets-manager.yaml


## Useful commands
```
kubectl delete -f infrastructure/galasa-plan-b-lon02/harbor/secret-tls.yaml
kubectl delete -f infrastructure/galasa-plan-b-lon02/harbor/secrets-manager.yaml

kubectl apply -f infrastructure/galasa-plan-b-lon02/harbor/secrets-manager.yaml
kubectl apply -f infrastructure/galasa-plan-b-lon02/harbor/secret-tls.yaml

kubectl get SecretStore -n harbor   
kubectl get ExternalSecrets -n harbor

kubectl describe SecretStore -n harbor   
kubectl describe ExternalSecrets -n harbor  
```

```
kubectl apply -f infrastructure/galasa-plan-b-lon02/harbor/harbor.yaml -n harbor 

kubectl rollout restart -n harbor deployments harbor-core harbor-jobservice harbor-portal harbor-registry
```

## Secrets Supplied/Used

- planb-dex-harbor-client 
  - Used to contact Dex from the harbor UI to make sure the users are authenticated.
  - Used from the argocd config
  - id: d57ad5a4-f733-8712-d7e2-5e4b81947ebb

- planb-harbor-admin-credentials 
  - The admin credentials of the harbor application.
  - id: d350313f-6f08-cd5b-538d-c8d95847961b

- planb-harbor-credentials 
  - The non-admin credentials of the harbor application. Used by pipelines to push images into the harbor repo.
  - id: 034fd081-b748-f5fc-c11d-41049b922fa7

## Non-devops things to do
- Log in using the oidc provider, that creates a user in harbor
- Log in using admin, give people admin access
- Copy the policies for cleaning up/retention and quotas from the old harbor system

## To test, pushing the http image to the library project
```
docker pull httpd
docker tag httpd:latest harbor.galasa-plan-b-lon02-3fdc13787e8248a7d32fa4e5af5b0294-0000.eu-gb.containers.appdomain.cloud/library/httpd:latest
docker logon harbor.galasa-plan-b-lon02-3fdc13787e8248a7d32fa4e5af5b0294-0000.eu-gb.containers.appdomain.cloud
```
... on the harbor UI, in the user profile details there is a CLI token to use when logging-in.
```
docker push harbor.galasa-plan-b-lon02-3fdc13787e8248a7d32fa4e5af5b0294-0000.eu-gb.containers.appdomain.cloud/library/httpd:latest
```

## Max body size
Initially, our push of an image to this harbor failed with this:
```
error parsing HTTP 413 response body: invalid character '<' looking for beginning of value: "<html>\r\n<head><title>413 Request Entity Too Large</title></head>\r\n<body>\r\n<center><h1>413 Request Entity Too Large</h1></center>\r\n<hr><center>nginx</center>\r\n</body>\r\n</html>\r\n"
```
The solition is to add an annotation into the `harbor.yaml` file:
```
kind: Ingress
metadata:
  name: "harbor-ingress"
  annotations:
    kubernetes.io/ingress.class: "public-iks-k8s-nginx"
    nginx.ingress.kubernetes.io/proxy-body-size: 500m   << This fixes the problem.
```

The above has been applied to the `harbor.yaml` this folder.

## Copy common images from the old cluster harbor to the new one...
```
export OLD_HARBOR="harbor.galasa.dev"
export NEW_HARBOR="harbor.galasa-plan-b-lon02-3fdc13787e8248a7d32fa4e5af5b0294-0000.eu-gb.containers.appdomain.cloud"

function copy_image {
  harbor_project=$1
  image=$2
  tag=":$3"
  echo "copying image $harbor_project/$image:$tag from ${OLD_HARBOR} to ${NEW_HARBOR}"
  docker pull ${OLD_HARBOR}/${harbor_project}/${image}${tag}
  rc=$?; if [[ "${rc}" != 0 ]]; then echo ">>>> Failed to pull" ; return 1 ; else
    docker tag ${OLD_HARBOR}/${harbor_project}/${image}${tag} ${NEW_HARBOR}/${harbor_project}/${image}${tag}
    rc=$?; if [[ "${rc}" != 0 ]]; then echo ">>>> Failed to tag" ; return 1 ; else
      docker push ${NEW_HARBOR}/${harbor_project}/${image}${tag}
      rc=$?; if [[ "${rc}" != 0 ]]; then echo ">>>> Failed to push" return 1 ; else
      fi
    fi
  fi
  return 0
}

copy_image common swagger main
copy_image common openapi main
copy_image common argocd-embedded main
copy_image common ghreceiver main
copy_image common tkn main
copy_image common alpine-test test
copy_image common argocd-cli main
copy_image common ghmonitor main
copy_image common ghstatus main
copy_image common ghverify main
copy_image common galasabld 
copy_image common gitcli main
copy_image common kubectl main
copy_image common gpg main
```