/*
 * Copyright contributors to the Galasa Project
 */
package main

import (
	"fmt"
	"log"
	"os"

	"net/http"

	cmd "github.com/galasa-dev/automation/build-images/github-webhook-receiver/pkg/cmd"
)

// The main method which gets called from the command-line. Our entry point.
func main() {

	// If the code panics, write out the message and exit badly.
	defer func() {
		errobj := recover()
		if errobj != nil {
			fmt.Fprintln(os.Stderr, errobj)
			log.Println(errobj)
			os.Exit(1)
		}
	}()

	// Get our inputs from the command-line args and environment variables.
	inputs, err := cmd.GetInputs()
	if err != nil {
		fail(err)
	}

	// Log our inputs for posterity in the trace.
	inputs.Log()

	// Register the http handler.
	http.HandleFunc("/", handler)

	// Listen for incoming HTTP traffic, and process it.
	listenOn := fmt.Sprintf(":%d", inputs.Port)
	err = http.ListenAndServe(listenOn, nil)

	// If we stopped serving, thenn there is an error.
	// Fail with the error message.
	fail(err)
}

// Handle in-coming http request, and reply with a response.
func handler(response http.ResponseWriter, request *http.Request) {

	// Log the request we've just been sent
	logRequest(request)

	fmt.Fprintf(response, "OK")
	response.WriteHeader(http.StatusOK)
}

// Logs a request, so we can see it on the output console.
func logRequest(request *http.Request) {
	log.Printf("URL : %s\n", request.URL)
	logRequestHeaders(request)
	logRequestBody(request)
}

func logRequestBody(request *http.Request) {
	// Log the body
	body := request.Body

	buffer := make([]byte, 1024)
	var bytesRead int = 100
	var err error = nil

	for (bytesRead > 0) && (err == nil) {
		bytesRead, err = body.Read(buffer)
		log.Printf("%s", string(buffer))
	}
}

func logRequestHeaders(request *http.Request) {
	// Log all the headers of this request.
	for name, values := range request.Header {
		for _, value := range values {
			log.Printf("Header %s = %s\n", name, value)
		}
	}
}

func fail(err error) {
	fmt.Fprintf(os.Stderr, "%s\n", err.Error())
	os.Exit(1)
}
