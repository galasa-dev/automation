# Generic Maven Repository Helm Chart

A generic, reusable Helm chart for deploying Maven repository artifacts in Kubernetes.

## Overview

This chart deploys a containerized Maven repository with:
- A Deployment running the Maven artifact container
- A Service exposing the deployment
- An Ingress for external access (optional)

## Usage

### Basic Installation

```bash
helm install <release-name> ./generic-maven-repository \
  --namespace <namespace> \
  --set name=<app-name> \
  --set imageName=<image-name> \
  --set ingress.pathSuffix=<path-suffix>
```

### Example: Deploying IVTS Repository

```bash
helm install ivts-repo ./generic-maven-repository \
  --namespace galasa-development \
  --set name=ivts \
  --set branch=main \
  --set imageName=ghcr.io/galasa-dev/ivts-maven-artefacts \
  --set imageTag=main \
  --set ingress.pathSuffix=ivts
```

### Example: Using a Values File

Create a values file (e.g., `ivts-values.yaml`):

```yaml
name: ivts
branch: main
imageName: ghcr.io/galasa-dev/ivts-maven-artefacts
imageTag: main

ingress:
  enabled: true
  externalHostname: development.galasa.dev
  ingressClassName: public-iks-k8s-nginx
  pathSuffix: ivts
  tls:
  - hosts:
      - development.galasa.dev
    secretName: devgalasa-tls-secret
```

Then install:

```bash
helm install ivts-repo ./generic-maven-repository \
  --namespace galasa-development \
  -f ivts-values.yaml
```

## Configuration

### Required Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `name` | Application/repository name (used as resource prefix) | `ivts` |
| `imageName` | Full container image name | `ghcr.io/galasa-dev/ivts-maven-artefacts` |
| `ingress.pathSuffix` | Path suffix for the maven repository | `ivts` |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `branch` | Git branch name (used in context root) | `main` |
| `imageTag` | Container image tag | `main` |
| `imagePullPolicy` | Image pull policy | `Always` |
| `ingress.enabled` | Enable/disable ingress | `true` |
| `ingress.externalHostname` | External hostname for ingress | `development.galasa.dev` |
| `ingress.ingressClassName` | Ingress class name | `public-iks-k8s-nginx` |
| `ingress.annotations` | Additional ingress annotations | `{}` |
| `ingress.tls` | TLS configuration | See values.yaml |

**Note:** The namespace is specified via `--namespace` flag or Helm's `--create-namespace` option, not in values.yaml. The chart uses `{{ .Release.Namespace }}` to reference the namespace.

## Path Structure

The chart creates the following URL path structure:

```
/{branch}/maven-repo/{pathSuffix}
```

For example, with `branch=main` and `pathSuffix=ivts`:
```
https://development.galasa.dev/main/maven-repo/ivts
```

## Deployment Details

### Fixed Configuration

The following settings are fixed in the templates:
- **Replicas:** 1
- **Revision History Limit:** 1
- **Container Port:** 80
- **Service Type:** ClusterIP
- **Service Port:** 80

These values were simplified from the original design and are not configurable via values.yaml.

## Migrating Existing Charts

To migrate an existing chart (e.g., `ivts`, `inttests`, `simplatform`) to use this generic chart:

### Example Migration: IVTS

**Old structure:**
```
infrastructure/galasa-kube1/galasa-development/ivts/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    └── ingress.yaml
```

**Migration steps:**

1. Create a values file for the specific repository:
```bash
cat > ivts-values.yaml <<EOF
name: ivts
branch: main
imageName: ghcr.io/galasa-dev/ivts-maven-artefacts
imageTag: main

ingress:
  enabled: true
  externalHostname: development.galasa.dev
  ingressClassName: public-iks-k8s-nginx
  pathSuffix: ivts
  tls:
  - hosts:
      - development.galasa.dev
    secretName: devgalasa-tls-secret
EOF
```

2. Install using the generic chart:
```bash
helm install ivts-repo ./generic-maven-repository \
  --namespace galasa-development \
  -f ivts-values.yaml
```

3. Verify the deployment:
```bash
kubectl get deployments -n galasa-development
kubectl get ingress -n galasa-development
```

4. Once verified, the old chart directory can be removed.

## Troubleshooting

### Check Deployment Status
```bash
kubectl get deployments -n <namespace>
kubectl describe deployment <name>-<branch> -n <namespace>
```

### Check Pod Logs
```bash
kubectl logs -n <namespace> -l app=<name>-<branch>
```

### Check Ingress
```bash
kubectl get ingress -n <namespace>
kubectl describe ingress <name>-<branch> -n <namespace>
```

### Verify Service
```bash
kubectl get service -n <namespace>
kubectl describe service <name>-<branch> -n <namespace>
```

### Common Issues

**Issue:** Resources not created in the expected namespace
- **Solution:** Ensure you specify `--namespace` flag during installation

**Issue:** Ingress not accessible
- **Solution:** Verify TLS secret exists in the namespace and hostname is correct

**Issue:** Pod fails to pull image
- **Solution:** Check image name and tag are correct, verify image registry access
