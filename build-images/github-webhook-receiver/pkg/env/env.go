/*
 * Copyright contributors to the Galasa project
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package env

import (
	"errors"
	"log"
)

type Inputs struct {
	GithubToken          string
	Port                 int32
	ExcludedRepositories []string
}

func (inputs *Inputs) Log() {
	log.Printf("Github token length: %d\n", len(inputs.GithubToken))
	log.Printf("Port to listen on: %d\n", inputs.Port)
	for _, repoName := range inputs.ExcludedRepositories {
		log.Printf("Excluding repository: %s", repoName)
	}
}

func ValidateGitHubToken(token string) error {
	var err error = nil
	if token == "" {
		err = errors.New("Error: GITHUBTOKEN environment variable is not set, or the --githubtoken parameter is not used.")
	}
	return err
}
