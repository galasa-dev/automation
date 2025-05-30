FROM ghcr.io/galasa-dev/ubuntu:20.04

ENV DEBIAN_FRONTEND="noninteractive" TZ="Europe/London"
RUN apt-get update && apt-get install -y unzip \
    curl \
    gpg && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install ca-certificates    