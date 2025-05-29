# Github webhook receiver

This receiver acts as place to which github webhooks are sent.
- The web hooks are HTTP requests, which are replied to using a 200 (OK) code. Any pull request will then not look like it's failed immediately, as it would without this service.
- The web hook HTTP requests are 'swallowed' with no code actually being built as a result.
However, the 'github monitor' process should notice that a build is necessary, and perform one.
- The web hook HTTP requests cause a notification to be sent back to the github pull request, saying that the build is 'pending'.




### Requirements
##### Github token 
Set the token as an environment variable in the runtime.
##### Github Org name
Pass the name of the github org with a flag: `-org=galasa-dev`
##### Github Hook ID
Each defined webhook has a corresponding ID number. To reduce API call limits this receiver expects the id to be pass: `-hook=<hook_id>`
You can find hook id's with this command:
```
curl -H "Accept: application/vnd.github+json" -H "Authorization: Bearer <TOKEN>" https://api.github.com/orgs/<ORG_NAME>/hooks
```

### Building the receiver docker image

Use docker from this repo to build this image. Example:
```
docker build -f ../../dockerfiles/common/githubreceiver.Dockerfile -t github-receiver .
```

### Running the receiver
For local testing, docker can be used to run this image. Example:
```
docker run \
    -v $(pwd)/config.yaml:/config.yaml \
    -v $(pwd)/latestId:/latestId \
    -e GITHUBTOKEN=<token> \ 
    github-receiver -org=galasa-dev -hook=<hook_id> -trigger-map=/config.yaml
```
This does expect the corresponding `config.yaml` and `latestId` file to be created. In normal operation the latestId file would be created automatically if no existing, but to track locally this file needs to be mounted.

## Deployment
This program/docker image gets deployed to the external-to-IBM cluster using argocd.
See the details [here](../../infrastructure/ibmcloud-galasadev-cluster/github-webhook-receiver/README.md)