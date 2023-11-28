/*
 * Copyright contributors to the Galasa project
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	cmd "github.com/galasa-dev/automation/build-images/github-webhook-receiver/pkg/cmd"
	"github.com/galasa-dev/automation/build-images/github-webhook-receiver/pkg/env"
	"github.com/galasa-dev/automation/build-images/github-webhook-receiver/pkg/types"
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
	logRequestHeaders(request)

	if request.Method != "POST" {
		// We don't care about things which are not posting.
		log.Printf("HTTP request arrived of type %s. We only care about POST requests.\n", request.Method)
	} else {
		bytes, err := io.ReadAll(request.Body)

		if err != nil {
			msg := "Failed to read the message payload"
			log.Println(msg)
			http.Error(response, msg, http.StatusBadRequest)
		} else {

			requestPayload, err := unmarshallPayload(bytes)

			if err != nil {
				msg := fmt.Sprintf("Failed to parse the message payload. %s\n", err.Error())
				log.Println(msg)
				http.Error(response, msg, http.StatusBadRequest)
			} else {
				_ = handlerWithPayload(response, request, *requestPayload)
			}
		}
	}
}

func unmarshallPayload(bytes []byte) (*types.Payload, error) {
	var requestPayload *types.Payload
	requestPayload = new(types.Payload)
	err := json.Unmarshal(bytes, requestPayload)
	if err != nil {
		// An error, so free up the memory.
		requestPayload = nil
	}
	return requestPayload, err
}

// List the "action" field value we want to take notice of and process.
// Anything else in the "action" field we ignore and just return success.
var pullRequestActions = map[string]string{"opened": "opened", "synchronize": "synchronize", "reopened": "reopened"}

func handlerWithPayload(response http.ResponseWriter, request *http.Request, requestPayload types.Payload) error {
	var err error = nil

	_, isPresent := pullRequestActions[requestPayload.Action]
	if !isPresent {
		log.Println("Event is neither a pull request \"opened\" nor a pull request \"synchronize\" or a pull request \"reopened\". Ignoring.")
	} else {

		// We know we are dealing with a pull request POST now... so it should have a payload.

		// The location of the pull request.
		pullRequestUrl := requestPayload.PullRequest.Url
		statusUrl := requestPayload.PullRequest.StatusesUrl
		githubIssueUrl := requestPayload.PullRequest.IssueUrl

		log.Printf("Pull request URL = %s\n", pullRequestUrl)
		log.Printf("Status URL = %s\n", statusUrl)
		log.Printf("gitHubIssue URL = %s\n", githubIssueUrl)
		log.Printf("Repository name = %s\n", requestPayload.PullRequest.Repository.Name)

		if isExcluded(requestPayload.PullRequest.Repository.Name, inputs.ExcludedRepositories) {
			log.Printf("Ignoring. Repository '%s' is configured to be excluded from Tekton building.\n", requestPayload.PullRequest.Repository.Name)
		} else {
			err = updateStatus("pending", "Building will start soon...", inputs.GithubToken, pullRequestUrl, statusUrl, githubIssueUrl)

			if err != nil {
				msg := "Couldn't update pull request state."
				log.Println(msg)
				http.Error(response, msg, http.StatusInternalServerError)
			}
		}

		if err == nil {
			msg := "OK"
			log.Println(msg)
			fmt.Fprintf(response, msg)
		}
	}
	return err
}

// isExcluded Figures out whether the specified repository name is one which has been excluded
// from Tekton building. Returns true if it has been excluded, false otherwise.
func isExcluded(repoName string, excludedRepoNames []string) bool {
	var excluded bool = false

	for _, excludedRepoName := range excludedRepoNames {
		if repoName == excludedRepoName {
			excluded = true
			break
		}
	}
	return excluded
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
// status : The status to set. "error" "failure" "pending" or "success"
// message : The text message to display against this status id
// pullRequestUrl : The URL where the pull request is located.
// statusUrl : The URL of where status should be posted into github.
// githubIssueUrl : Where the github issue is found.
func updateStatus(status string, message string, githubToken string,
	pullRequestUrl string, statusUrl string, githubIssueUrl string) error {

	body := fmt.Sprintf("{\"state\":\"%s\", \"description\":\"%s\", \"context\":\"Tekton\"}", status, message)
	log.Printf("Updating status . Body: %s\n", body)

	req, _ := http.NewRequest("POST", statusUrl, strings.NewReader(body))
	req.Header.Add("Accept", "application/vnd.github+json")
	response, err := sendRequest(req, githubToken)
	if err != nil {
		log.Printf("Failed to send POST request to github. Reason %s\n", err.Error())
	} else {
		log.Println("Github responded to the POST request.")

		if response.StatusCode == http.StatusOK {
			log.Println("Github response code is OK")
		} else {
			log.Printf("Github response status code is %d", response.StatusCode)
			responseBodyBytes, _ := io.ReadAll(response.Body)
			responseBody := string(responseBodyBytes[:])
			log.Printf("Github response body : %s\n", responseBody)
		}
	}
	return err
}

// sendRequest() - Issue a request using a specified github token.
func sendRequest(req *http.Request, githubToken string) (*http.Response, error) {
	req.Header.Add("Authorization", fmt.Sprintf("Bearer %s", githubToken))
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode == http.StatusAccepted ||
		resp.StatusCode == http.StatusCreated ||
		resp.StatusCode == http.StatusOK {
		return resp, err
	}
	return resp, fmt.Errorf("bad response: %s", resp.Status)
}
