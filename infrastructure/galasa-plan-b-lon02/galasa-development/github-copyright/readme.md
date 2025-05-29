


We need to go create some kubernetes resources objects:

1. Deployment, that runs your container image, 1 replica, dont forget to include the port number in the spec.

2. Service, please use the port number 3001 to connect your service to your container.

3. External secret on which the deployment depends, so gitgub can be sure it's the correct authenticated app back-end.

The secret name is: `githubapp-copyright-unit-test-key`
The secret itself is something like:
```
-----BEGIN RSA PRIVATE KEY-----
MI...
...=
-----END RSA PRIVATE KEY-----
```
