/*
 * Copyright contributors to the Galasa project
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/galasa-dev/automation/build-images/github-verify/pkg/types"
)

const layout = "2006-01-02T15:04:05Z"

var approvalRequest = "Automatic triggering of the build is cancelled as user is not a member of the approved groups. Please ask an admin to review this PR and create a comment on the PR stating 'Approved for building'"
var token string
var client = http.Client{
	Timeout: 30 * time.Second,
}

// This program is called either because:
//   - Some pull request has been opened/re-opened/synchronized.
//     (in which case the userId passed is the person who did the push/open/re-open)
//   - Some pull request has been reviewed, and the comment "Approved for building"
//     has been submitted as a review comment.
//     (in which case the userId passed is the person who did the review)
//
// Objectives:
//
//		Look at the pull request being built and check the userID passed is a member of
//		an approved group within the github organisation.
//
//	 If the PR and userid passes the checks, then the PR is told that a build is
//	 now in-progress. If the checks fail, then a suitable comment will be appended
//	 to the PR such as "Build not run, please request an admin to approve"
func main() {
	token = os.Getenv("GITHUBTOKEN")
	userId := flag.Int("userid", -1, "The UserId of PR opener")
	prUrl := flag.String("pr", "", "URL of the pr to verify")
	org := flag.String("org", "", "which github org are we looking for users in")
	approvedGroups := flag.String("approved-groups", "", "the github groups get auto-build on PRs")
	action := flag.String("action", "", "what github action occured")
	flag.Parse()

	// Get PR object
	var pr types.Pull
	req, _ := http.NewRequest("GET", *prUrl, nil)
	resp, err := client.Do(req)
	if err != nil {
		//handle error
	}
	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		//handle error
	}
	json.Unmarshal(data, &pr)

	// Decide on what action to take
	fmt.Println("Starting check for action: " + *action)
	switch *action {
	case "opened", "reopened":
		if CheckForIdInApprovedTeam(*userId, *org, strings.Split(*approvedGroups, ",")) {
			updateStatus("pending", "Build submited", pr)
			os.Exit(0)
		}
		commentOnPr(approvalRequest, pr)
		updateStatus("pending", "Waiting admin approval", pr)
		os.Exit(1)
	case "synchronize":
		if CheckForIdInApprovedTeam(*userId, *org, strings.Split(*approvedGroups, ",")) {
			updateStatus("pending", "Build submited", pr)
			os.Exit(0)
		}
		commentOnPr(approvalRequest, pr)
		updateStatus("pending", "Waiting admin approval", pr)
		os.Exit(1)
	case "submitted":
		if CheckForIdInApprovedTeam(*userId, *org, strings.Split(*approvedGroups, ",")) {
			updateStatus("pending", "Build submited", pr)
			os.Exit(0)
		}
		updateStatus("pending", "Waiting admin approval", pr)
		commentOnPr("Build not run, please request an admin to approve", pr)
		os.Exit(1)
	default:
		os.Exit(1)
	}
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

func CheckForIdInApprovedTeam(userid int, org string, approvedTeams []string) bool {
	orgId, err := fetchOrgId(org)
	if err != nil {
		panic(err)
	}
	approvedUsers, err := fetchUsers(org, orgId, approvedTeams)
	for _, approvedUser := range approvedUsers {
		if userid == approvedUser {
			return true
		}
	}

	return false
}

func fetchTeamIds(org string, approvedTeams []string) (map[string]int, error) {
	m := make(map[string]int)
	var teamsJson []types.Team
	req, _ := http.NewRequest("GET", fmt.Sprintf("https://api.github.com/orgs/%s/teams", org), nil)
	resp, err := sendRequest(req)
	if err != nil {
		return m, err
	}
	data, err := ioutil.ReadAll(resp.Body)
	json.Unmarshal(data, &teamsJson)

	for _, teamJson := range teamsJson {
		for _, team := range approvedTeams {
			if team == teamJson.Name {
				m[team] = teamJson.Id
			}
		}

	}
	return m, nil
}

func fetchUsers(org string, orgid int, approvedTeams []string) ([]int, error) {
	var approvedUsers []int
	teams, err := fetchTeamIds(org, approvedTeams)
	if err != nil {
		return nil, err
	}

	for _, teamId := range teams {
		var teamMembers []types.Member
		req, _ := http.NewRequest("GET", fmt.Sprintf("https://api.github.com/organizations/%v/team/%v/members", orgid, teamId), nil)
		resp, err := sendRequest(req)
		if err != nil {
			return nil, err
		}
		data, err := ioutil.ReadAll(resp.Body)
		json.Unmarshal(data, &teamMembers)
		for _, member := range teamMembers {
			approvedUsers = append(approvedUsers, member.Id)
		}
	}
	return approvedUsers, nil
}

func fetchOrgId(org string) (int, error) {
	var orgJson types.Org
	req, _ := http.NewRequest("GET", fmt.Sprintf("https://api.github.com/orgs/%s", org), nil)
	resp, err := sendRequest(req)
	if err != nil {
		return -1, err
	}
	data, err := ioutil.ReadAll(resp.Body)
	json.Unmarshal(data, &orgJson)
	return orgJson.Id, nil
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
