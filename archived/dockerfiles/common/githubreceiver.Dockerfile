FROM ghcr.io/galasa-dev/alpine:3.18.6
COPY bin/ghreceiver /go/bin/ghreceiver
ENTRYPOINT ["/go/bin/ghreceiver"]