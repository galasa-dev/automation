FROM ghcr.io/galasa-dev/alpine:3.18.4

RUN apk --no-cache add curl

RUN curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/v3.2.5/download/argocd-linux-amd64
RUN install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
RUN rm argocd-linux-amd64

ENTRYPOINT ["argocd"]
