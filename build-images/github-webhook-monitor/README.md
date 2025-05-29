# Github Monitor

This monitor acts as a pass through of webhooks delivered from github to a nohup. This will poll controlled by a cron to determine if any events happening within a specified org required any actions.

### Requirements
##### Github token 
Set the token as an environment variable in the runtime.
##### Github Org name
Pass the name of the github org with a flag: `-org=galasa-dev`
##### Github Hook ID
Each defined webhook has a corresponding ID number. To reduce API call limits this monitor expects the id to be pass: `-hook=<hook_id>`
You can find hook id's with this command:
```
curl -H "Accept: application/vnd.github+json" -H "Authorization: Bearer <TOKEN>" https://api.github.com/orgs/<ORG_NAME>/hooks
```
##### Event Mapper config
Passed as a yaml file, the event list ties a github event type to a corresponding event_listener URL.
``` 
events: 
  pull_request:
      eventListener: "something.namespace.svc.cluster.local"
  pull_request_review:
      eventListener: "somethingElse.namespace.svc.cluster.local"
```
The path for this config is expected to be passed with this flag: `-trigger-map=/config.yaml`

### Building the monitor

Use docker from this repo to build this image. Example:
```
docker build -f ../../dockerfiles/common/githubmonitor.Dockerfile -t github-monitor .
```

### Running the monitor
For local testing, docker can be used to run this image. Example:
```
docker run \
    -v $(pwd)/config.yaml:/config.yaml \
    -v $(pwd)/latestId:/latestId \
    -e GITHUBTOKEN=<token> \ 
    github-monitor -org=galasa-dev -hook=<hook_id> -trigger-map=/config.yaml
```
This does expect the corresponding `config.yaml` and `latestId` file to be created. In normal operation the latestId file would be created automatically if no existing, but to track locally this file needs to be mounted.

The monitor is designed to be run with a kubernetes cron job. For example:
```
apiVersion: batch/v1
kind: CronJob
metadata:
  name: github-event-monitor
  namespace: <Namespace>
spec:
  # Every 2 mins
  schedule: "*/2 * * * *"
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
            - name: kubectl
              image: <image_name>
              env:
                - name: GITHUBTOKEN
                  valueFrom:
                  secretKeyRef:
                    name: <github_token_secret>
                    key: token
                    optional: false
              args: ["-org=galasa-dev","-hook=<hook_id>","-trigger-map=/config.yaml"]
              volumeMounts:
              - mountPath: /
                name: trigger-map
                subPath: config.yaml
          volumes:
          - name: trigger-map
            configMap:
              name: <name_config>
```