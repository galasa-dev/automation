/*
 * Copyright contributors to the Galasa project
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/galasa.dev/automation/offline-tools/copyrighter/pkg/files"
	"github.com/spf13/cobra"
)

var (
	RootCmd = &cobra.Command{
		Use:     "galasacopyrighter",
		Short:   "Tool to set copyright headers into source files.",
		Long:    `A tool for setting Galasa copyright headers into source files.`,
		Version: "1.0",
		Run:     executeCommand,
	}

	folderPath string
)

const (
	COPYRIGHT_LINE_CONTRIBUTORS = "Copyright contributors to the Galasa project"
	COPYRIGHT_LINE_LICENSE      = "SPDX-License-Identifier: EPL-2.0"

	COMMENT_START_JAVA    = "/*"
	COMMENT_CONTINUE_JAVA = " *"
	COMMENT_END_JAVA      = " */"
	COMMENT_HASH          = "#"
)

func init() {
	cmd := RootCmd
	cmd.PersistentFlags().StringVarP(&folderPath, "folder", "f", "", "The folder containing files which needs transforming.")
	cmd.MarkFlagRequired("folder")

	cmd.SetOut(os.Stdout)
}

func Execute() {
	err := RootCmd.Execute()
	if err != nil {
		println(err.Error())
	}
}

func executeCommand(cmd *cobra.Command, args []string) {
	fs := files.NewOSFileSystem()
	processFolder(fs, folderPath)
}

// Everything from here on down can be easily unit tested.
func processFolder(fs files.FileSystem, folderPath string) error {
	filesToProcess, err := fs.GetAllFilesInFolder(folderPath)
	if err == nil {
		errorCount := 0
		for _, filePath := range filesToProcess {

			processingError := processFile(fs, filePath)
			if processingError != nil {
				println(processingError.Error())
				errorCount += 1
			}
		}
		if errorCount > 0 {
			err = fmt.Errorf("failure. Found %d errors", errorCount)
		}
	}
	return err
}

func processFile(fs files.FileSystem, filePath string) error {
	var err error = nil
	var commentType string

	if strings.Contains(filePath, "/.git/") {
		// Don't process files in the .git folders...
	} else {
		var contents string = ""

		commentType = ""
		if strings.HasSuffix(filePath, ".java") || strings.HasSuffix(filePath, ".go") || strings.HasSuffix(filePath, ".js") || strings.HasSuffix(filePath, ".scss") || strings.HasSuffix(filePath, ".ts") || strings.HasSuffix(filePath, ".tsx") {
			commentType = COMMENT_CONTINUE_JAVA
		} else if strings.HasSuffix(filePath, ".yaml") || strings.HasSuffix(filePath, ".sh") {
			commentType = COMMENT_HASH
		}

		if commentType != "" {
			contents, err = fs.ReadTextFile(filePath)

			if err == nil {
				newContents, err := setCopyright(contents, commentType)

				if err == nil {
					fs.WriteTextFile(filePath, newContents)
				}
			}
		} else {
			err = cantProcessFile(fs, filePath)
		}
	}
	return err
}

func cantProcessFile(fs files.FileSystem, filePath string) error {
	contents, err := fs.ReadTextFile(filePath)
	if strings.Contains(contents, "Copyright") {
		if strings.Contains(contents, "Galasa") {
			fmt.Printf("Tool not able to process a file which contains a Galasa copyright statement: %s\n", filePath)
		} else if strings.Contains(contents, "IBM") {
			fmt.Printf("Tool not able to process a file which contains a IBM copyright statement: %s\n", filePath)
		} else {
			fmt.Printf("Tool not able to process a file which contains a non-Galasa/IBM copyright statement: %s\n", filePath)
		}
	}
	return err
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

func setCopyright(input string, commentType string) (string, error) {
	var output string = ""
	var inputWithNoCopyright string = ""
	var dontAddCopyright bool
	var err error
	var newLine int

	if commentType == COMMENT_CONTINUE_JAVA { //file contains opening and closing coments
		inputWithNoCopyright, err, dontAddCopyright = stripOutExistingCopyright(input)
		if dontAddCopyright {
			return input, err
		}
		if err == nil {
			output = addNewCopyrightAtStart(inputWithNoCopyright)
		}
	} else if commentType == COMMENT_HASH { //file contains hash comments

		firstHash := strings.Index(input, COMMENT_HASH)
		if firstHash != -1 {
			newLine = strings.Index(input[firstHash:], "\n") + 1
		}
		//check if it's a bash script
		firstLineOfFile := input[:newLine]

		if fileIsBashScript(firstLineOfFile) {
			newFirstHash := strings.Index(input[newLine:], COMMENT_HASH)

			if newFirstHash != -1 {
				inputWithNoCopyright, dontAddCopyright = stripOutExistingCopyrightHash(input[newLine:])
				if dontAddCopyright {
					return input, err
				} else {
					output = firstLineOfFile + "\n" + addNewCopyrightAtStartHash(inputWithNoCopyright)
				}
			} else {
				output = firstLineOfFile + "\n" + addNewCopyrightAtStartHash(input[newLine:])
			}

		} else { //yaml file with comments
			if firstHash != -1 {
				inputWithNoCopyright, dontAddCopyright = stripOutExistingCopyrightHash(input)
				if dontAddCopyright {
					return input, err
				} else {
					output = addNewCopyrightAtStartHash(inputWithNoCopyright)
				}
			} else {
				output = addNewCopyrightAtStartHash(input)
				return output, err
			}
		}

	}

	return output, err
}

func stripOutExistingCopyright(input string) (string, error, bool) {
	var dontAddCopyright bool
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
				startIndexOfFollowingInput = findNextNoneWhiteSpaceCharacter(input, startIndexOfFollowingInput)

				afterFirstCommentEnder := input[startIndexOfFollowingInput:]

				commentToCheck := input[firstCommentOpener:startIndexOfFollowingInput]
				if copyrightContainsIBMOrGalasa(commentToCheck) {
					output = beforeFirstCommentInput + afterFirstCommentEnder
					dontAddCopyright = false
				} else if strings.Contains(commentToCheck, "Copyright") { //copyright of external party
					dontAddCopyright = true
				} else {
					output = beforeFirstCommentInput + "\n" + commentToCheck + afterFirstCommentEnder
					dontAddCopyright = false
				}
			}
		}

	} else {
		output = input
	}
	return output, err, dontAddCopyright
}

func stripOutExistingCopyrightHash(input string) (string, bool) {
	var output string
	var firstHash int
	var lastHash int
	var newLine int
	var commentToCheck string
	var leadingText string
	var dontAddCopyright = false

	input = strings.TrimSpace(input)
	firstHash = strings.Index(input, COMMENT_HASH)
	newLine = strings.Index(input, "\n")

	//for leading texts
	for newLine < firstHash {
		leadingText = input[:newLine]
		newLine += strings.Index(input[firstHash:], "\n")
	}

	if input[newLine+1] != '#' { //for one line comment
		lastHash = newLine
	} else { // for multi-line comment
		for {
			newLine += strings.Index(input[newLine+1:], "\n") + 1
			if input[newLine+1] == '#' {
				//move on to find next newLine
			} else if input[newLine+1] != '#' {
				lastHash = newLine
				break
			}
		}
	}

	commentToCheck = input[firstHash:lastHash]

	if commentNeedsNoChange(commentToCheck) {
		dontAddCopyright = true
		output = input
	} else {
		if copyrightContainsIBMOrGalasa(commentToCheck) {
			if leadingText != "" {
				output = "\n" + leadingText + input[lastHash+1:]
			} else {
				output = input[lastHash:]
			}
		} else if strings.Contains(commentToCheck, "Copyright") { //copyright of external party
			dontAddCopyright = true
			output = input
		} else {
			output = input
		}
	}

	return output, dontAddCopyright
}

func addNewCopyrightAtStartHash(input string) string {
	var buffer = strings.Builder{}

	buffer.WriteString(fmt.Sprintf("%s\n", COMMENT_HASH))
	buffer.WriteString(fmt.Sprintf("%s %s\n", COMMENT_HASH, COPYRIGHT_LINE_CONTRIBUTORS))
	buffer.WriteString(fmt.Sprintf("%s\n", COMMENT_HASH))
	buffer.WriteString(fmt.Sprintf("%s %s\n", COMMENT_HASH, COPYRIGHT_LINE_LICENSE))
	buffer.WriteString(fmt.Sprintf("%s\n", COMMENT_HASH))
	buffer.WriteString(input)

	return buffer.String()
}

func copyrightContainsIBMOrGalasa(commentToCheck string) bool {
	var removeComment bool

	if strings.Contains(commentToCheck, "Property of IBM") {
		removeComment = true
	} else if strings.Contains(commentToCheck, "Copyright") {
		if strings.Contains(commentToCheck, "IBM") || strings.Contains(commentToCheck, "Galasa") {
			removeComment = true
		}
	} else {
		removeComment = false
	}
	return removeComment
}

func findNextNoneWhiteSpaceCharacter(input string, startIndexOfFollowingInput int) int {
	for {
		c := input[startIndexOfFollowingInput]
		if c == ' ' || c == '\t' || c == '\n' {
			startIndexOfFollowingInput += 1
		} else {
			break
		}
	}
	return startIndexOfFollowingInput
}

func commentNeedsNoChange(commentToCheck string) bool {
	standardCopyright := `#
 # Copyright contributors to the Galasa project
 #
 # SPDX-License-Identifier: EPL-2.0
 #`
	return commentToCheck == standardCopyright
}

func fileIsBashScript(firstLineToCheck string) bool {
	firstLineToCheck = strings.TrimSpace(firstLineToCheck)
	return strings.HasPrefix(firstLineToCheck, "#!")
}
