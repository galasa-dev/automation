/*
 * Copyright contributors to the Galasa project
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package cmd

import (
	"fmt"
	"strings"

	"github.com/spf13/cobra"
)

var (
	RootCmd = &cobra.Command{
		Use:     "galasacopyrighter",
		Short:   "Tool to set copyright headers into source files.",
		Long:    `A tool for setting Galasa copyright headers into source files.`,
		Version: "1.0",
	}
)

const (
	COPYRIGHT_LINE_CONTRIBUTORS = "Copyright contributors to the Galasa project"
	COPYRIGHT_LINE_LICENSE      = "SPDX-License-Identifier: EPL-2.0"

	COMMENT_START_JAVA    = "/*"
	COMMENT_CONTINUE_JAVA = " *"
	COMMENT_END_JAVA      = " */"
	COMMENT_DOUBLE_STROKE = "//"
)

func Execute() {
}

func addNewCopyrightAtStart(input string) string {
	var buffer = strings.Builder{}

	buffer.WriteString(fmt.Sprintf("%s\n", COMMENT_START_JAVA))
	buffer.WriteString(fmt.Sprintf("%s %s\n", COMMENT_CONTINUE_JAVA, COPYRIGHT_LINE_CONTRIBUTORS))
	buffer.WriteString(fmt.Sprintf("%s\n", COMMENT_CONTINUE_JAVA))
	buffer.WriteString(fmt.Sprintf("%s %s\n", COMMENT_CONTINUE_JAVA, COPYRIGHT_LINE_LICENSE))
	buffer.WriteString(fmt.Sprintf("%s\n", COMMENT_END_JAVA))
	buffer.WriteString(input)

	return buffer.String()
}

func setCopyright(input string) (string, error) {
	var output string = ""
	inputWithNoCopyright, err := stripOutExistingCopyright(input)
	if err == nil {
		output = addNewCopyrightAtStart(inputWithNoCopyright)
	}
	return output, err
}

func stripOutExistingCopyright(input string) (string, error) {
	var err error = nil
	var output string
	firstCommentOpener := strings.Index(input, COMMENT_START_JAVA)

	if firstCommentOpener >= 0 {
		firstCommentEnder := strings.Index(input, strings.Trim(COMMENT_END_JAVA, " \t\n"))

		if firstCommentEnder < 0 {
			err = fmt.Errorf("comment not closed. Comment started at character position %d is not closed",
				firstCommentOpener)
		} else {

			if firstCommentEnder <= firstCommentOpener {
				err = fmt.Errorf("closing comment marker found before the starting comment marker. Comment started at character position %d, but ended at position %d",
					firstCommentOpener, firstCommentEnder)
			} else {
				beforeFirstCommentInput := input[:firstCommentOpener]
				startIndexOfFollowingInput := firstCommentEnder + len(COMMENT_END_JAVA)

				// Skip to the next newline... so that newline gets stripped also.
				for {
					c := input[startIndexOfFollowingInput]
					if c == ' ' || c == '\t' || c == '\n' {
						startIndexOfFollowingInput += 1
					} else {
						break
					}
				}

				afterFirstCommentEnder := input[startIndexOfFollowingInput:]

				//checking if the comment contains the old copyright text
				commentToCheck := input[firstCommentOpener:startIndexOfFollowingInput]
				if strings.Contains(commentToCheck, "Copyright ") {
					output = beforeFirstCommentInput + afterFirstCommentEnder
				} else {
					output = "\n" + beforeFirstCommentInput + "\n" + commentToCheck + afterFirstCommentEnder
				}
			}
		}

	} else {
		output = input
	}
	return output, err
}
