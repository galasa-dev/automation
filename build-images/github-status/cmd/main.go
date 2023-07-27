/*
 * Copyright contributors to the Galasa project
 *
 * SPDX-License-Identifier: EPL-2.0
 */
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
	prUrl := flag.String("prUrl", "", "URL of the pr to verify")
	statusesUrl := flag.String("statusesUrl", "", "URL of status to send update request to")
	issueUrl := flag.String("issueUrl", "", "URL of the issue")
	pipelineRunName := flag.String("pipelineRunName", "", "The name of the Pipeline Run triggered by PR")
	flag.Parse()

	pull := &types.Pull{
		Url:       *prUrl,
		StatusUrl: *statusesUrl,
		IssueUrl:  *issueUrl,
	}

	if *status != "Succeeded" {
		err := updateStatus("failure", "Build failed", *pull)
		if err != nil {
			fmt.Printf("Error updating PR status: %s\n", err)
			os.Exit(1)
		}
		failureUrl := fmt.Sprintf("http://localhost:8001/api/v1/namespaces/tekton-pipelines/services/tekton-dashboard:http/proxy/#/namespaces/galasa-build/pipelineruns/%s", *pipelineRunName)
		err1 := commentOnPr(fmt.Sprintf("Build failed, see %s for details. If you are unable to do so, please contact a member of the Galasa team.", failureUrl), *pull)
		if err1 != nil {
			fmt.Println("Error commenting on PR: %s\n", err)
			os.Exit(1)
		}
	} else {
		err := updateStatus("success", "Build successful", *pull)
		if err != nil {
			fmt.Printf("Error updating PR status: %s\n", err)
			os.Exit(1)
		}
		err1 := commentOnPr("Build successful", *pull)
		if err1 != nil {
			fmt.Println("Error commenting on PR: %s\n", err)
			os.Exit(1)
		}
	}
}

func updateStatus(status, message string, pr types.Pull) error {
	body := fmt.Sprintf("{\"state\":\"%s\", \"description\":\"%s\", \"context\":\"Tekton\"}", status, message)
	req, _ := http.NewRequest("POST", pr.StatusUrl, strings.NewReader(body))
	req.Header.Add("Accept", "application/vnd.github+json")
	_, err := sendRequest(req)
	return err
}

func commentOnPr(message string, pr types.Pull) error {
	body := fmt.Sprintf("{\"body\": \"%s\"}", message)
	req, _ := http.NewRequest("POST", fmt.Sprintf("%s/comments", pr.IssueUrl), strings.NewReader(body))
	_, err := sendRequest(req)
	return err
}

func sendRequest(req *http.Request) (*http.Response, error) {
	req.Header.Add("Authorization", fmt.Sprintf("Bearer %s", token))
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
