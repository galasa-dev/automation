#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#

all: clean tests github-webhook-receiver

delta-build: tests github-webhook-receiver

clean:
	rm -fr build
	rm -fr bin

setup:
	go get github.com/stretchr/testify/assert
	go get github.com/spf13/viper

github-webhook-receiver: bin/ghmonitor-linux-amd64 \
	bin/ghmonitor-darwin-amd64 \
	bin/ghmonitor-darwin-arm64


tests: source 
	mkdir -p build
	go test -v ./pkg/* -cover -coverprofile=build/coverage.out
	go tool cover -html=build/coverage.out -o build/coverage.html
	go tool cover -func=build/coverage.out > build/coverage.txt
	cat build/coverage.txt
	go test -v ./cmd/* -cover -coverprofile=build/coverage.out
	go tool cover -html=build/coverage.out -o build/coverage.html
	go tool cover -func=build/coverage.out > build/coverage.txt
	cat build/coverage.txt

source: ./cmd/*.go ./pkg/mapper/*.go ./pkg/jsonTypes/*.go

bin/ghmonitor-linux-amd64 : source
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o bin/ghmonitor-linux-amd64 ./cmd

bin/ghmonitor-darwin-amd64 : source
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -o bin/ghmonitor-darwin-amd64 ./cmd

bin/ghmonitor-darwin-arm64 : source
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -o bin/ghmonitor-darwin-arm64 ./cmd





