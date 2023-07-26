/*
 * Copyright contributors to the Galasa project
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package types

type Payload struct {
	Action      string      `json:"action"` // "opened" or "synchronize"
	PullRequest PullRequest `json:"pull_request"`
}

type PullRequest struct {
	Url         string     `json:"url"`
	IssueUrl    string     `json:"issue_url"`
	State       string     `json:"state"` // Expected to be "open"
	Title       string     `json:"title"` // So we can log the pull request title.
	StatusesUrl string     `json:"statuses_url"`
	Repository  Repository `json:"repository"`
}

type Repository struct {
	Name     string `json:"name"`
	FullName string `json:"full_name"`
}
