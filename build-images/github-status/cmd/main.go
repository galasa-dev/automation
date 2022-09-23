package main

import (
	"flag"
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

	status := flag.String("status", "", "Status of the Tekton build")
	prUrl := flag.String("pr", "", "URL of the pr to verify")
	statusesUrl := flag.String("statusesUrl", "", "URL of status to send update request to")
	issueUrl := flag.String("issueUrl", "", "URL of the issue")
	pipelineRunName := flag.String("pipelineRunName", "", "The name of the Pipeline Run triggered by PR")

	fmt.Println(status)
	fmt.Println(prUrl)
	fmt.Println(statusesUrl)
	fmt.Println(issueUrl)
	fmt.Println(pipelineRunName)

	pull := &types.Pull{
		Url:       *prUrl,
		StatusUrl: *statusesUrl,
		IssueUrl:  *issueUrl,
	}

	fmt.Println(pull)

	if *status != "Succeeded" {
		updateStatus("failure", "Build failed", *pull)
		failureUrl := fmt.Sprintf("https://tekton.galasa.dev/#/namespaces/galasa-pipelines/pipelineruns/%s", *pipelineRunName)
		commentOnPr(fmt.Sprintf("Build failed, see %s for details", failureUrl), *pull)
	} else {
		updateStatus("success", "Build successful", *pull)
		commentOnPr("Build successful", *pull)
	}

	// Github: failure, success, error
}

func updateStatus(status, message string, pr types.Pull) {
	body := fmt.Sprintf("{\"state\":\"%s\", \"description\":\"%s\", \"context\":\"Tekton\"}", status, message)
	req, _ := http.NewRequest("POST", pr.StatusUrl, strings.NewReader(body))
	req.Header.Add("Accept", "application/vnd.github+json")
	fmt.Println(req)
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
