/*
 * Copyright contributors to the Galasa project
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package types

type Pull struct {
	Url        string `json:"url"`
	IssueUrl   string `json:"issue_url"`
	StatusUrl  string `json:"statuses_url"`
	CommitsUrl string `json:"commits_url"`
	Commits    int    `json:"commits"`
	Head       Head   `json:"head"`
}

type Head struct {
	Sha string `json:"sha"`
}
