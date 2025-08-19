# triggers.galasa.dev - what does it do?

## triggers.galasa.dev domain

An A record exists for the triggers.galasa.dev domain: `A | triggers.galasa.dev | 169.50.192.70`

## GitHub Webhook

A Webhook is set up on the galasa-dev GitHub organisation with a Payload URL of https://triggers.galasa.dev. POST requests are sent to that URL with details of the subscribed events (Pushes and Workflow runs).

All deliveries to the triggers.galasa.dev Webhook have the following warning:
```
We couldn't deliver this payload: tls: failed to verify certificate: x509: certificate is valid for *.galasa-plan-b-lon02-3fdc13787e8248a7d32fa4e5af5b0294-0000.eu-gb.containers.appdomain.cloud, galasa-plan-b-lon02-3fdc13787e8248a7d32fa4e5af5b0294-0000.eu-gb.containers.appdomain.cloud, gal...
```

This is because triggers.galasa.dev does not have a TLS certificate and so it defaults to the default TLS certificate provided by IBM Cloud (this is because the `triggers-ingress` described below is handled by the "public-iks-k8s-nginx" ingress controller). This warning is irrelevant however as the POST requests about the events are not processed directly so it doesn't matter that the payload cannot be delivered. The [github-webhook-monitor](../../build-images/github-webhook-monitor/cmd/main.go) sends a GET request to https://api.github.com/orgs/galasa-dev/hooks/386623630/deliveries?per_page=50 and then processes the event deliveries itself.

The ConfigMap [githubmonitor-configmap](../../build-images/github-webhook-monitor/config.yaml) is used to route the different events to a particular EventListener. Events are sent to one of two EventListeners based on what the event type is, `push` or `workflow_run`. The EventListeners then call Tekton Pipelines.

Note that in the [githubmonitor-configmap](../../build-images/github-webhook-monitor/config.yaml), the EventListener URLs protocol is HTTP and therefore triggers.galasa.dev is responsible only for internal-cluster traffic, hence why it does not need a TLS certificate.

## Kubernetes resources

On the **cicsk8s** Kubernetes cluster, there is a Custom Resource Definition for an Ingress, `triggers-ingress`, that configures how traffic gets routed to services running inside the cluster. This traffic comes from inside the cluster from the github-monitor. Therefore, HTTPS is not configured for this Ingress as triggers.galasa.dev is responsible only for internal-cluster traffic.

The Ingress has several rules, which define how traffic should be routed based on hostnames and paths.

Example rule:
```yaml
- host: triggers.galasa.dev
  http:
    paths:
    - backend:
        service:
          name: el-github-main-builder-listener
          port:
            number: 8080
      path: /main
      pathType: Prefix
```

