#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#

all: tests galasacopyrighter

galasacopyrighter: bin/galasacopyrighter-darwin-arm64 

galasacopyrighter-source : \
	./cmd/galasacopyrighter/*.go \
	./pkg/cmd/*.go \
	./pkg/files/*.go

tests: galasacopyrighter-source build/coverage.txt build/coverage.html

bin/galasacopyrighter-darwin-arm64 : galasacopyrighter-source
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -o bin/galasacopyrighter-darwin-arm64 ./cmd/galasacopyrighter	

build/coverage.out : galasacopyrighter-source
	mkdir -p build
	go test -v -cover -coverprofile=build/coverage.out -coverpkg ./pkg/cmd ./pkg/...

build/coverage.html : build/coverage.out
	go tool cover -html=build/coverage.out -o build/coverage.html

build/coverage.txt : build/coverage.out
	go tool cover -func=build/coverage.out > build/coverage.txt
	cat build/coverage.txt

clean:
	rm -fr bin/galasacopyrighter*
	rm -fr build/*
