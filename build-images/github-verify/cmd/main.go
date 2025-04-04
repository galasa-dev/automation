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
	"io"
	"log"
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
	var exitCode = 1
	token = os.Getenv("GITHUBTOKEN")
	userId := flag.Int("userid", -1, "The UserId of PR opener")
	prUrl := flag.String("pr", "", "URL of the pr to verify")
	org := flag.String("org", "", "which github org are we looking for users in")
	approvedGroups := flag.String("approved-groups", "", "the github groups get auto-build on PRs")
	action := flag.String("action", "", "what github action occurred")
	flag.Parse()

	log.Printf("github-verify tool.\n")
	log.Printf("UserId of the PR opener : %v\n", userId)
	log.Printf("URL of the PR to verify : %v\n", prUrl)
	log.Printf("Github organisation we are looking for the user in : %v\n", org)
	log.Printf("Github github groups which get auto-build on PRs : %v\n", approvedGroups)
	log.Printf("Which github action just occurred : %v\n", action)

	// Get PR object
	var pr types.Pull
	req, _ := http.NewRequest("GET", *prUrl, nil)
	resp, err := client.Do(req)
	if err != nil {
		panic("GET failed. " + err.Error())
	} else {
		var data []byte
		data, err = io.ReadAll(resp.Body)
		if err != nil {
			panic("GET response payload could not be read. " + err.Error())
		} else {
			err = json.Unmarshal(data, &pr)
			if err != nil {
				panic("GET response could not be un-marshalled. " + err.Error())
			} else {
				// Decide on what action to take
				fmt.Println("Starting check for action: " + *action)
				var isApproved bool

				isApproved, err = CheckForIdInApprovedTeam(*userId, *org, strings.Split(*approvedGroups, ","))
				if err != nil {
					panic("CheckForIdInApprovedTeam could not be checked. " + err.Error())
				} else {

					switch *action {
					case "opened", "reopened":

						if isApproved {
							err = updateStatus("pending", "Build submited", pr)
							if err == nil {
								exitCode = 0
							}
						} else {
							err = commentOnPr(approvalRequest, pr)
							if err == nil {
								err = updateStatus("pending", "Waiting admin approval", pr)
							}
						}

					case "synchronize":

						if isApproved {
							err = updateStatus("pending", "Build submited", pr)
							if err == nil {
								exitCode = 0
							}
						} else {
							err = commentOnPr(approvalRequest, pr)
							if err == nil {
								err = updateStatus("pending", "Waiting admin approval", pr)
							}
						}

					case "submitted":

						if isApproved {
							err = updateStatus("pending", "Build submited", pr)
							if err == nil {
								exitCode = 0
							}
						} else {
							err = updateStatus("pending", "Waiting admin approval", pr)
							if err == nil {
								err = commentOnPr("Build not run, please request an admin to approve", pr)
							}
						}

					default:
					}
				}
			}
		}
	}

	if err != nil {
		exitCode = 1
	}

	os.Exit(exitCode)
}

func updateStatus(status, message string, pr types.Pull) error {
	body := fmt.Sprintf("{\"state\":\"%s\", \"description\":\"%s\", \"context\":\"Tekton\"}", status, message)
	req, _ := http.NewRequest("POST", pr.StatusUrl, strings.NewReader(body))
	req.Header.Add("Accept", "application/vnd.github+json")
	_, err := sendRequest(req)
	if err != nil {
		panic("Failed to Update the status on the PR " + err.Error())
	}
	return err
}

func commentOnPr(message string, pr types.Pull) error {
	body := fmt.Sprintf("{\"body\": \"%s\"}", message)
	req, _ := http.NewRequest("POST", fmt.Sprintf("%s/comments", pr.IssueUrl), strings.NewReader(body))
	_, err := sendRequest(req)
	if err != nil {
		panic("Failed to comment on PR. " + err.Error())
	}
	return err
}

func CheckForIdInApprovedTeam(userid int, org string, approvedTeams []string) (bool, error) {
	orgId, err := fetchOrgId(org)
	var isApproved bool
	if err == nil {

		var approvedUsers []int
		approvedUsers, err = fetchUsers(org, orgId, approvedTeams)
		if err == nil {
			for _, approvedUser := range approvedUsers {
				if userid == approvedUser {
					isApproved = true
					break
				}
			}
		}
	}

	return isApproved, err
}

func fetchTeamIds(org string, approvedTeams []string) (map[string]int, error) {
	m := make(map[string]int)
	var teamsJson []types.Team
	req, _ := http.NewRequest("GET", fmt.Sprintf("https://api.github.com/orgs/%s/teams", org), nil)
	resp, err := sendRequest(req)
	if err != nil {
		panic("Failed to GET the team data. " + err.Error())
	} else {
		var data []byte
		data, err = io.ReadAll(resp.Body)
		if err == nil {
			err = json.Unmarshal(data, &teamsJson)

			if err == nil {
				for _, teamJson := range teamsJson {
					for _, team := range approvedTeams {
						if team == teamJson.Name {
							m[team] = teamJson.Id
						}
					}
				}
			}
		}
	}
	return m, err
}

func fetchUsers(org string, orgid int, approvedTeams []string) ([]int, error) {
	var err error
	var approvedUsers []int
	var teams map[string]int
	teams, err = fetchTeamIds(org, approvedTeams)
	if err == nil {
		for _, teamId := range teams {
			var teamMembers []types.Member
			req, _ := http.NewRequest("GET", fmt.Sprintf("https://api.github.com/organizations/%v/team/%v/members", orgid, teamId), nil)
			var resp *http.Response
			resp, err = sendRequest(req)
			if err == nil {
				var data []byte
				data, err = io.ReadAll(resp.Body)
				if err == nil {
					err = json.Unmarshal(data, &teamMembers)
					if err == nil {
						for _, member := range teamMembers {
							approvedUsers = append(approvedUsers, member.Id)
						}
					}
				}
			}
		}
	}
	return approvedUsers, err
}

func fetchOrgId(org string) (int, error) {
	var err error
	var orgId int
	var orgJson types.Org
	req, err := http.NewRequest("GET", fmt.Sprintf("https://api.github.com/orgs/%s", org), nil)
	if err == nil {
		resp, err := sendRequest(req)
		if err == nil {
			var data []byte
			data, err = io.ReadAll(resp.Body)
			if err == nil {
				err = json.Unmarshal(data, &orgJson)
				if err == nil {
					orgId = orgJson.Id
				}
			}
		}
	}
	return orgId, err
}

func sendRequest(req *http.Request) (*http.Response, error) {
	req.Header.Add("Authorization", fmt.Sprintf("Bearer %s", token))
	resp, err := client.Do(req)
	if err == nil {
		switch resp.StatusCode {
		case http.StatusAccepted:
			fallthrough
		case http.StatusCreated:
			fallthrough
		case http.StatusOK:
			// does not fall through
		default:
			err = fmt.Errorf("bad response: %s", resp.Status)
		}
	} else {
		err = fmt.Errorf("Sending the request failed. %v", err)
	}

	if err != nil {
		panic(fmt.Sprintf("Sending request failed. %v", err.Error()))
	}
	return resp, err
}
