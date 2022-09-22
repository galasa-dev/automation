package main

import (
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/galasa-dev/automation/build-images/github-status/pkg/types"
)

var token string
var client = http.Client{
	Timeout: 30 * time.Second,
}

func main() {
	token = os.Getenv("GITHUBTOKEN")
	// If not Succeeded, then we fail

	// Gihub: failure, success, error
}

func updateStatus(status, message string, pr types.Pull) {
	body := fmt.Sprintf("{\"state\":\"%s\", \"description\":\"%s\", \"context\":\"Tekton\"}", status, message)
	req, _ := http.NewRequest("POST", pr.StatusUrl, strings.NewReader(body))
	req.Header.Add("Accept", "application/vnd.github+json")
	sendRequest(req)
}

func commentOnPr(message string, pr types.Pull) {
	body := fmt.Sprintf("{\"body\": \"%s\"}", message)
	req, _ := http.NewRequest("POST", fmt.Sprintf("%s/comments", pr.IssueUrl), strings.NewReader(body))
	sendRequest(req)
}

func sendRequest(req *http.Request) (*http.Response, error) {
	req.Header.Add("Authorization", fmt.Sprintf("Bearer %s", token))
	resp, err := client.Do(req)
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
