/*
 * Copyright contributors to the Galasa project
 */
package main

import (
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"net/http"

	cmd "github.com/galasa-dev/automation/build-images/github-webhook-receiver/pkg/cmd"
	"github.com/galasa-dev/automation/build-images/github-webhook-receiver/pkg/env"
)

var (
	// An http client we use to send information back to github.
	client = http.Client{
		Timeout: 30 * time.Second,
	}

	// Our parameters and env variables packaged up into a structure.
	inputs *env.Inputs
)

// The main method which gets called from the command-line. Our entry point.
//
// This tool does the following:
// - Sits there listening on a port for in-coming HTTP traffic.
// - When a github change causes github to send a webhook, saying that a build needs to be done...
//   - This tool replies "OK" so that the build doesn't appear to be broken when viewed in the UI
//   - This tool tells the PR (if it is a PR kicking off things) that the status of the build is 'pending...'
//
// Overall, this should lead to a cleaner user experience when doing pull requests.
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
	gatheredInputs, err := cmd.GetInputs()
	if err != nil {
		fail(err)
	}

	// Log our inputs for posterity in the trace.
	gatheredInputs.Log()

	// Save away the inputs so the handler can get it.
	inputs = gatheredInputs

	// Register the http handler.
	http.HandleFunc("/", handler)

	// Listen for incoming HTTP traffic, and process it.
	listenOn := fmt.Sprintf(":%d", gatheredInputs.Port)
	err = http.ListenAndServe(listenOn, nil)

	// If we stopped serving, thenn there is an error.
	// Fail with the error message.
	fail(err)
}

// Handle in-coming http request, and reply with a response.
func handler(response http.ResponseWriter, request *http.Request) {

	// Log the request we've just been sent
	logRequest(request)

	// The location of the pull request.
	// TODO: Should be found from the request message body.
	pullRequestUrl := ""

	statusUrl := ""
	githubIssueUrl := ""

	updateStatus("Pending...", "Building will start soon...", inputs.GithubToken, pullRequestUrl, statusUrl, githubIssueUrl)

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

// updateStatus() - Tells the pull request to update it's status for the tekton build.
// Parameters:
// status : The status id to update
// message : The text message to display against this status id
// pullRequestUrl : The URL where the pull request is located.
// statusUrl : The URL of where status should be posted into github.
// githubIssueUrl : Where the github issue is found.
func updateStatus(status string, message string, githubToken string,
	pullRequestUrl string, statusUrl string, githubIssueUrl string) error {

	body := fmt.Sprintf("{\"state\":\"%s\", \"description\":\"%s\", \"context\":\"Tekton\"}", status, message)
	req, _ := http.NewRequest("POST", statusUrl, strings.NewReader(body))
	req.Header.Add("Accept", "application/vnd.github+json")
	_, err := sendRequest(req, githubToken)
	return err
}

// sendRequest() - Issue a request using a specified github token.
func sendRequest(req *http.Request, githubToken string) (*http.Response, error) {
	req.Header.Add("Authorization", fmt.Sprintf("Bearer %s", githubToken))
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode == http.StatusAccepted {
		return resp, err
	}
	if resp.StatusCode == http.StatusCreated {
		return resp, err
	}
	if resp.StatusCode == http.StatusOK {
		return resp, err
	}
	return resp, fmt.Errorf("bad response: %s", resp.Status)
}
