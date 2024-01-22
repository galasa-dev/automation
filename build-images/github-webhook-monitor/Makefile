#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#

all: docker_build 

ghmonitor-source: \
	./cmd/*.go \
	./pkg/jsonTypes/*.go \
	./pkg/mapper/*.go 

bin/ghmonitor: ghmonitor-source
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o bin/ghmonitor ./cmd

docker-build: ../../dockerfiles/common/github-monitor-dockerfile bin/ghmonitor
	docker build -f ../../dockerfiles/common/github-monitor-dockerfile -t github-monitor .

docker-run: 
	docker_run.sh