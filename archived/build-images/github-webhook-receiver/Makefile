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
	go get golang.org/x/net/http2

github-webhook-receiver: bin/github-webhook-receiver-linux-amd64 \
	bin/github-webhook-receiver-windows-amd64.exe  \
	bin/github-webhook-receiver-darwin-amd64 \
	bin/github-webhook-receiver-darwin-arm64


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

source: ./cmd/github-webhook-receiver/*.go ./pkg/env/*.go ./pkg/cmd/*.go

bin/github-webhook-receiver-linux-amd64 : source
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o bin/github-webhook-receiver-linux-amd64 ./cmd/github-webhook-receiver

bin/github-webhook-receiver-windows-amd64.exe : source
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -o bin/github-webhook-receiver-windows-amd64.exe ./cmd/github-webhook-receiver

bin/github-webhook-receiver-darwin-amd64 : source
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -o bin/github-webhook-receiver-darwin-amd64 ./cmd/github-webhook-receiver

bin/github-webhook-receiver-darwin-arm64 : source
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -o bin/github-webhook-receiver-darwin-arm64 ./cmd/github-webhook-receiver





