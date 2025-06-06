FROM ghcr.io/galasa-dev/alpine:3.18.6

RUN apk add curl
RUN apk add sudo

RUN curl -LO https://github.com/tektoncd/cli/releases/download/v0.33.0/tkn_0.33.0_Linux_x86_64.tar.gz
RUN sudo tar xvzf tkn_0.33.0_Linux_x86_64.tar.gz -C /usr/local/bin/ tkn

COPY git-workspace-template.yaml /tmp/git-workspace-template.yaml
COPY pod-template.yaml /tmp/pod-template.yaml