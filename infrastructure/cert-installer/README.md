# cert-installer Helm chart

This is a Helm chart that installs the resources needed to issue a certificate for a service exposed via a Kubernetes Ingress using cert-manager.

The chart assumes that you have [cert-manager](https://cert-manager.io) installed on your Kubernetes cluster.

When installed, the following resources are created:
- An `Issuer` resource, configured to use the ACME CA server
- A `Certificate` resource representing the TLS certificate that was issued for your service

## Installing the Helm chart

Configure the Helm chart's values via a YAML file:

1. Create a copy of the chart's [`values.yaml`](./values.yaml) file
2. Add a host name into the `dnsNames` value for the host that you wish to issue a certificate for. For example:

```yaml
dnsNames:
  - myservice.galasa.dev
```

2. Provide an email address for the `email` value, for example:

```yaml
email: user@example.com
```

Install the Helm chart:
1. Run the following command:

```
helm upgrade --install --values /path/to/values.yaml <installation-name> /path/to/cert-installer --namespace <namespace>
```

where:
- `/path/to/values.yaml` is the file path to the YAML file containing the values that were configured in the previous steps
- `<installation-name>` is a name that should be associated with the Helm chart's installation
- `/path/to/cert-installer` is the file path to the `cert-installer` directory on your machine
- `<namespace>` is the Kubernetes namespace that you wish to install the Helm chart into

2. Check that a certificate was issued by getting the status of the Certificate resource in Kubernetes with:

```
kubectl get certificates
```

This will produce the following output:

```
NAME                 READY   SECRET                      AGE
myservice-tls-cert   False   myservice-tls-cert-secret   34s
```

For more information about the status of the certificate, you can run:
```
kubectl describe certificate <certificate-name>
```
where `<certificate-name>` is the name of the Certificate resource that was created. This will display a set of events, like:

```
Events:
  Type    Reason     Age   From                                       Message
  ----    ------     ----  ----                                       -------
  Normal  Issuing    30s   cert-manager-certificates-trigger          Issuing certificate as Secret does not exist
  Normal  Generated  30s   cert-manager-certificates-key-manager      Stored new private key in temporary Secret resource "myservice-tls-cert-hzrr2"
  Normal  Requested  30s   cert-manager-certificates-request-manager  Created new CertificateRequest resource "myservice-tls-cert-1
```

After a short period of time, the certificate will be issued and its `READY` status should change from `False` to `True` when running `kubectl get certificate`. A new event should also appear when the certificate is issued when running `kubectl describe certificate <certificate-name>`:

```
Events:
  Type    Reason     Age   From                                       Message
  ----    ------     ----  ----                                       -------
  ...
  Normal  Issuing    6m22s  cert-manager-certificates-issuing          The certificate has been successfully issued
```

3. Now that a certificate has been successfully issued, update the `useIssuerProductionUrl` value in your values file from `false` to `true`, so it should look like:

```yaml
useIssuerProductionUrl: true
```

4. Run the following command to switch from using the ACME staging issuer to the production issuer:

```
helm upgrade --values /path/to/values.yaml <installation-name> /path/to/cert-installer --namespace <namespace>
```

where:
- `/path/to/values.yaml` is the file path to the YAML file containing the values that were configured in the previous steps
- `<installation-name>` is the name that was set when the Helm chart was installed
- `/path/to/cert-installer` is the file path to the `cert-installer` directory on your machine
- `<namespace>` is the Kubernetes namespace that the Helm chart was installed into

5. Wait for the new certificate to be issued using the ACME CA production server, monitoring the status of the certificate by running `kubectl get certificates`

You should now have a certificate that is ready to be used by your Ingress resources.

## Using the Certificate in Ingresses

Once you have an issued certificate, you can modify your Kubernetes Ingress definitions to use the certificate:

1. Add a `tls` section into your Ingress YAML definition's `spec` field. For example, if the DNS name that you issued a certificate for is `myservice.galasa.dev` and the cert-installer's Helm installation name that you provided was `myservice`, then the Ingress would look like:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-example-ingress
spec:
  # --------------------------------------------------
  # Add a TLS section like this into your Ingress YAML
  tls:
  - hosts:
      - myservice.galasa.dev
    secretName: myservice-secret
  # --------------------------------------------------
  rules:
  - host: myservice.galasa.dev
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: service1
            port:
              number: 80
```

2. Apply the changes to your Ingress resource (if using Helm, you can run a `helm upgrade` command) and then the service should be using the new certificate
