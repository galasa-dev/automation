#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#

all: bin/ghmonitor docker-build

ghmonitor-source: \
	./cmd/*.go \
	./pkg/jsonTypes/*.go \
	./pkg/mapper/*.go 

bin/ghmonitor: ghmonitor-source
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o bin/ghmonitor ./cmd

docker-build: ../../dockerfiles/common/githubmonitor.Dockerfile bin/ghmonitor
	docker build -f ../../dockerfiles/common/githubmonitor.Dockerfile -t ghcr.io/galasa-dev/ghmonitor:main .

docker-run:
	sh docker_run.sh