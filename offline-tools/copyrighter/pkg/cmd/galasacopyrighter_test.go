/*
 * Copyright contributors to the Galasa project
 *
 * SPDX-License-Identifier: EPL-2.0
 */

package cmd

import (
	"strings"
	"testing"

	"github.com/galasa.dev/automation/offline-tools/copyrighter/pkg/files"
	"github.com/stretchr/testify/assert"
)

func TestCanAddCopyrightWhenNoneExistsAlready(t *testing.T) {
	var input = `package mypackage
	class AClass {
		// Does nothing.
	}
	`

	output, err := setCopyright(input)

	assert.NotNil(t, output)
	assert.Nil(t, err)

	if !strings.HasPrefix(output, `/*
 * Copyright contributors to the Galasa project
 *
 * SPDX-License-Identifier: EPL-2.0
 */`) {
		assert.Fail(t, "Copyright statement is not at the start of the output. output:\n%s", output)
	}
}

func TestCopyrightAddedToOriginalContent(t *testing.T) {
	// Given..
	var input = `package mypackage
	class AClass {
		// Does nothing.
	}
	`

	// When...
	output, err := setCopyright(input)

	// Then..
	assert.Nil(t, err)
	assert.NotNil(t, output)

	packageLineLocation := strings.Index(output, "package mypackage")
	assert.Greater(t, packageLineLocation, 0, "Original file content should be returned with the copyright.")
}

func TestCopyrightWhereNoneExistsAddedToStartOfFile(t *testing.T) {
	// Given..
	var input = `/*
 * Copyright contributors to the Galasa project
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package mypackage
class AClass {
	// Does nothing.
}
`

	// When...
	output, err := setCopyright(input)

	// Then..
	assert.NotNil(t, output)
	assert.Nil(t, err)

	contributorLineCount := strings.Count(output, "Copyright contributors to the Galasa project")
	assert.Equal(t, contributorLineCount, 1, "Contributor line has been repeated.")

	licenseLineCount := strings.Count(output, "SPDX-License-Identifier: EPL-2.0\n")
	assert.Equal(t, licenseLineCount, 1, "License line has been repeated.")
}

func TestCopyrightNotAddedWhenPresentAlready(t *testing.T) {
	// Given..
	var input = `package mypackage
	class AClass {
		// Does nothing.
	}
	`

	// When...
	output, err := setCopyright(input)

	// Then..
	assert.Nil(t, err)
	assert.NotNil(t, output)
}

func TestCanStripOutFirstCommentAndTrailingWhiteSpace(t *testing.T) {
	// Given..
	var input = `/*
 * Copyright line here
 *
 * SPDX-License-Identifier: EPL-2.0
 */       ` + "\t" + "\n" + "package mypackage"

	// When...
	output, err := stripOutExistingCopyright(input)

	// Then..
	assert.Nil(t, err)
	assert.NotNil(t, output)
	assert.Equal(t, output, "package mypackage")
	assert.NotContains(t, output, "Copyright line here")
}

func TestCanStripOutFirstCommentWhenThereIsNoComment(t *testing.T) {
	// Given..
	var input = `package mypackage`

	// When...
	output, err := stripOutExistingCopyright(input)

	// Then..
	assert.Nil(t, err)
	assert.NotNil(t, output)
	assert.Equal(t, "package mypackage", output)
}

func TestCanStripOutFirstCommentMostCommonExistingCopyrightStatement(t *testing.T) {
	// Given..
	var input = `/*
 * Copyright is present here
 */
 package mypackage`

	// When...
	output, err := stripOutExistingCopyright(input)

	// Then..
	assert.Nil(t, err)
	assert.NotNil(t, output)
	assert.Equal(t, output, "package mypackage")
	assert.NotContains(t, output, "Copyright is present here")
}

func TestCanStripOutFirstCommentLeadingTextShouldBePreserved(t *testing.T) {
	// Given..
	var input = `leading text here
/*
 * Copyright contributors to the Galasa project
 */
 package mypackage`

	// When...
	output, err := stripOutExistingCopyright(input)

	// Then..
	assert.Nil(t, err)
	assert.NotNil(t, output)
	assert.Equal(t, output, "leading text here\npackage mypackage")
}

func TestStrippingOutFirstCommentWithNoClosingTagFailsWithError(t *testing.T) {
	// Given..
	var input = `
/*
 * Copyright is found here
 
 package mypackage`

	// When...
	_, err := stripOutExistingCopyright(input)

	// Then..
	assert.NotNil(t, err)
	assert.Contains(t, err.Error(), "comment not closed.")
}

func TestClosingCommentIsBeforeOpeningCommentFailsWithError(t *testing.T) {
	// Given..
	var input = `
*/
 * Copyright contributors to the Galasa project
 /*
 package mypackage`

	// When...
	_, err := stripOutExistingCopyright(input)

	// Then..
	assert.NotNil(t, err)
	assert.Contains(t, err.Error(), "closing comment marker found before the starting comment marker")
}

func TestCommentIsPresentButDoesNotIncludeCopyright(t *testing.T) {
	// Given..
	var input = `
/*
 * Hello, World
 */
 package mypackage`

	// When...
	output, _ := setCopyright(input)

	// Then..
	assert.NotNil(t, output)
	assert.Contains(t, output, "* Hello, World")
	assert.Contains(t, output, "* Copyright contributors to the Galasa project")
}

func TestCommentDoesNotIncludeCopyrightButStartsWithClosingComment(t *testing.T) {
	// Given..
	var input = `
*/
 * Hello, World
 /*
 package mypackage`

	// When...
	_, err := setCopyright(input)

	// Then..
	assert.NotNil(t, err)
	assert.Contains(t, err.Error(), "closing comment marker found before the starting comment marker")
}

func TestCommentIsPresentAndIncludesCopyright(t *testing.T) {
	// Given..
	var input = `
/*
 * CCopyright(c) is found here
 */
 package mypackage`

	// When...
	output, _ := setCopyright(input)

	// Then..
	assert.NotNil(t, output)
	assert.Contains(t, output, "* SPDX-License-Identifier: EPL-2.0")
	assert.NotContains(t, output, "Copyright(c) is found here")
}

func TestCommentNeedsNoChange(t *testing.T) {
	// Given..
	var input = `/*
 * Copyright contributors to the Galasa project
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package mypackage`

	// When...
	output, _ := setCopyright(input)

	// Then..
	assert.NotNil(t, output)
	assert.Equal(t, output, input)
}

func TestReplaceCommentAtStartOfYamlFile(t *testing.T) {
	// Given..
	var input = `# Copyright contributors to the Galasa project
apiVersion: v1
kind: PersistentVolumeClaim
metadata:`

	// When...
	output, _ := setCopyright(input)

	// Then..
	assert.NotNil(t, output)
	assert.NotContains(t, output, "# Copyright contributors to the Galasa project\napiVersion:")
	assert.Contains(t, output, "# SPDX-License-Identifier: EPL-2.0")
	assert.Contains(t, output, "apiVersion: v1\nkind: PersistentVolumeClaim")
}

func TestAppliesChangesToJavaFileInFolder(t *testing.T) {
	fs := files.NewMockFileSystem()
	fs.MkdirAll("/my/folder/")
	fs.WriteTextFile("/my/folder/myJavaFile.java", `Java source code`)

	err := processFolder(fs, "/my/folder/")

	assert.Nil(t, err)

	contents, err := fs.ReadTextFile("/my/folder/myJavaFile.java")
	assert.Nil(t, err)
	assert.Contains(t, contents, "Java source code")
	assert.Contains(t, contents, "Copyright")
}

func TestDoesNotApplyChangesToTextFileInFolder(t *testing.T) {
	fs := files.NewMockFileSystem()
	fs.MkdirAll("/my/folder/")
	fs.WriteTextFile("/my/folder/myJavaFile.txt", `Java source code`)

	err := processFolder(fs, "/my/folder/")

	assert.Nil(t, err)

	contents, err := fs.ReadTextFile("/my/folder/myJavaFile.txt")
	assert.Nil(t, err)
	assert.Equal(t, contents, "Java source code")
}

func TestAppliesChangesToGoFileInFolder(t *testing.T) {
	fs := files.NewMockFileSystem()
	fs.MkdirAll("/my/folder/")
	fs.WriteTextFile("/my/folder/myJavaFile.go", `Go source code`)

	err := processFolder(fs, "/my/folder/")

	assert.Nil(t, err)

	contents, err := fs.ReadTextFile("/my/folder/myJavaFile.go")
	assert.Nil(t, err)
	assert.Contains(t, contents, "Go source code")
	assert.Contains(t, contents, "Copyright")
}

func TestAppliesChangesToJavaScriptFileInFolder(t *testing.T) {
	fs := files.NewMockFileSystem()
	fs.MkdirAll("/my/folder/")
	fs.WriteTextFile("/my/folder/myJavaFile.js", `Javascript source code`)

	err := processFolder(fs, "/my/folder/")

	assert.Nil(t, err)

	contents, err := fs.ReadTextFile("/my/folder/myJavaFile.js")
	assert.Nil(t, err)
	assert.Contains(t, contents, "Javascript source code")
	assert.Contains(t, contents, "Copyright")
}
