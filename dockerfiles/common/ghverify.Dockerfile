FROM ghcr.io/galasa-dev/alpine:3.18.6
COPY bin/ghverify /go/bin/ghverify
ENTRYPOINT ["/go/bin/ghverify"]
