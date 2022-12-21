/*
 * Copyright contributors to the Galasa project
 */
package cmd

import (
	env "github.com/galasa-dev/automation/build-images/github-webhook-receiver/pkg/env"
	"github.com/spf13/cobra"
	viper "github.com/spf13/viper"
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

	githubToken string
	port        int32
)

func init() {
	rootCmd.PersistentFlags().Int32VarP(&port, "port", "p", DEFAULT_PORT, "Port to listen on.")
	rootCmd.SetHelpCommand(&cobra.Command{Hidden: true})
	rootCmd.PersistentFlags().StringVarP(&githubToken, "githubtoken", "g",
		viper.GetString("GITHUBTOKEN"), "The github token. Defaults to value of the GITHUBTOKEN environment variable.")
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

		// Do any validation we can.
		err = env.ValidateGitHubToken(inputs.GithubToken)
	}

	return inputs, err
}

func gatherInputs(cmd *cobra.Command, args []string) {
	// Do nothing. The inputs have been gathered already if we got this far.
}
