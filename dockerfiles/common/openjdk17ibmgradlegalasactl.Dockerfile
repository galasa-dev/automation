FROM ghcr.io/galasa-dev/openjdk17-ibm-gradle:main

RUN curl -L \
    -o /usr/local/bin/galasactl \
    https://github.com/galasa-dev/galasa/releases/download/v0.47.0/galasactl-linux-amd64 && \
    chmod +x /usr/local/bin/galasactl

RUN /usr/local/bin/galasactl --help

ENTRYPOINT ["/usr/local/bin/galasactl"]