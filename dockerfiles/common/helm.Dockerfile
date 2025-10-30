FROM ghcr.io/galasa-dev/alpine:3.18.6

RUN apk add curl

RUN mkdir -p /opt/k8s/bin && \
  curl -LO https://get.helm.sh/helm-v3.19.0-linux-amd64.tar.gz && \
  tar xvzf helm-v3.19.0-linux-amd64.tar.gz && \
  mv linux-amd64/helm /opt/k8s/bin/helm

ENV PATH=$PATH:/opt/k8s/bin

ENTRYPOINT ["helm"]
