/*
 * Copyright contributors to the Galasa project
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package env

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestValidateGitHubTokenFailsWithBlank(t *testing.T) {
	err := ValidateGitHubToken("")
	expected := "Error: GITHUBTOKEN environment variable is not set, or the --githubtoken parameter is not used."
	if assert.NotNil(t, err) {
		errorString := err.Error()
		assert.Equal(t, expected, errorString, "ValidateGitHubToken didn't fail with the correct response.")
	}
}

func TestValidateGitHubTokenWorksWithGoodValue(t *testing.T) {
	err := ValidateGitHubToken("goodToken")
	assert.Nil(t, err, "validateGitHubToken failed when it had good input.")
}
