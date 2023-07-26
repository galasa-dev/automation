/*
 * Copyright contributors to the Galasa project
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package cmd

import (
	"os"

	env "github.com/galasa-dev/automation/build-images/github-webhook-receiver/pkg/env"
	"github.com/spf13/cobra"
)

const DEFAULT_PORT = 80

var (
	rootCmd = &cobra.Command{
		Use:     "github-webhook-receiver",
		Short:   "Tool to receive webhook requests",
		Long:    `A tool to receive webhook requests from github when a pull request is created/updated.`,
		Version: "unknowncliversion-unknowngithash",
		Run:     gatherInputs,
	}

	githubToken   string
	port          int32
	excludedRepos []string
)

func init() {
	defaultGitHubToken := os.Getenv("GITHUBTOKEN")
	rootCmd.PersistentFlags().Int32VarP(&port, "port", "p", DEFAULT_PORT, "Port to listen on.")
	rootCmd.SetHelpCommand(&cobra.Command{Hidden: true})
	rootCmd.PersistentFlags().StringVarP(&githubToken, "githubtoken", "g",
		defaultGitHubToken, "The github token. Defaults to value of the GITHUBTOKEN environment variable.")

	excludeUsage := "Name of a repository which will be silently excluded from processing." +
		"Multiple instance of this flag can be used to specify many repositories which are excluded."
	rootCmd.Flags().StringSliceVar(&excludedRepos, "exclude", make([]string, 0), excludeUsage)
}

func GetInputs() (*env.Inputs, error) {

	var inputs *env.Inputs = nil

	// Use cobra to gather command-line inputs.
	err := rootCmd.Execute()

	if err == nil {

		// Allocate a structure into which input parameters/args can be placed.
		inputs = new(env.Inputs)

		// Populate the structure
		inputs.Port = port
		inputs.GithubToken = githubToken
		inputs.ExcludedRepositories = excludedRepos

		// Do any validation we can.
		err = env.ValidateGitHubToken(inputs.GithubToken)
	}

	return inputs, err
}

func gatherInputs(cmd *cobra.Command, args []string) {
	// Do nothing. The inputs have been gathered already if we got this far.
}
