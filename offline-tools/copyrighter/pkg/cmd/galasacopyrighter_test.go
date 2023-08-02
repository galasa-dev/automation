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

	output, err := setCopyright(input, " *")

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
	output, err := setCopyright(input, " *")

	// Then..
	assert.Nil(t, err)
	assert.NotNil(t, output)

	packageLineLocation := strings.Index(output, "package mypackage")
	assert.Greater(t, packageLineLocation, 0, "Original file content should be returned with the copyright.")
}

func TestCopyrightNotAddedWhenPresentAlready(t *testing.T) {
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
	output, err := setCopyright(input, " *")

	// Then..
	assert.NotNil(t, output)
	assert.Nil(t, err)

	contributorLineCount := strings.Count(output, "Copyright contributors to the Galasa project")
	assert.Equal(t, contributorLineCount, 1, "Contributor line has been repeated.")

	licenseLineCount := strings.Count(output, "SPDX-License-Identifier: EPL-2.0\n")
	assert.Equal(t, licenseLineCount, 1, "License line has been repeated.")
}

func TestCopyrightWhereNoneExistsAddedToStartOfFile(t *testing.T) {
	// Given..
	var input = `package mypackage
	class AClass {
		// Does nothing.
	}
	`

	// When...
	output, err := setCopyright(input, " *")

	// Then..
	assert.Nil(t, err)
	assert.NotNil(t, output)
}

func TestCanStripOutFirstCommentAndTrailingWhiteSpace(t *testing.T) {
	// Given..
	var input = `/*
 * Copyright line here IBM
 *
 * SPDX-License-Identifier: EPL-2.0
 */       ` + "\t" + "\n" + "package mypackage"

	// When...
	output, err, _ := stripOutExistingCopyright(input)

	// Then..
	assert.Nil(t, err)
	assert.NotNil(t, output)
	assert.Equal(t, output, "package mypackage")
	assert.NotContains(t, output, "Copyright line here IBM")
}

func TestCanStripOutFirstCommentWhenThereIsNoComment(t *testing.T) {
	// Given..
	var input = `package mypackage`

	// When...
	output, err, _ := stripOutExistingCopyright(input)

	// Then..
	assert.Nil(t, err)
	assert.NotNil(t, output)
	assert.Equal(t, "package mypackage", output)
}

func TestCanStripOutFirstCommentMostCommonExistingCopyrightStatement(t *testing.T) {
	// Given..
	var input = `/*
 * Copyright in Galasa file
 */
package mypackage`

	// When...
	output, err, _ := stripOutExistingCopyright(input)

	// Then..
	assert.Nil(t, err)
	assert.NotNil(t, output)
	assert.Equal(t, output, "package mypackage")
	assert.NotContains(t, output, "Copyright in Galasa file")
}

func TestCanStripOutFirstCommentLeadingTextShouldBePreserved(t *testing.T) {
	// Given..
	var input = `leading text here
/*
 * Copyright contributors to the Galasa project
 */
package mypackage`

	// When...
	output, err, _ := stripOutExistingCopyright(input)

	// Then..
	assert.Nil(t, err)
	assert.NotNil(t, output)
	assert.Equal(t, output, "leading text here\npackage mypackage")
}

func TestStrippingOutFirstCommentWithNoClosingTagFailsWithError(t *testing.T) {
	// Given..
	var input = `
/*
 * Copyright is Galasa found here

package mypackage`

	// When...
	_, err, _ := stripOutExistingCopyright(input)

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
	_, err, _ := stripOutExistingCopyright(input)

	// Then..
	assert.NotNil(t, err)
	assert.Contains(t, err.Error(), "closing comment marker found before the starting comment marker")
}

func TestCommentIsPresentButDoesNotIncludeCopyrightToBeRemoved(t *testing.T) {
	// Given..
	var input = `
/*
 * Hello, World Copyright
 */
package mypackage`

	// When...
	output, _ := setCopyright(input, " *")

	// Then..
	assert.NotNil(t, output)
	assert.Contains(t, output, "* Hello, World Copyright")
	assert.NotContains(t, output, "* Copyright contributors to the Galasa project")
}

func TestCommentDoesNotIncludeCopyrightToBeRemovedButStartsWithClosingComment(t *testing.T) {
	// Given..
	var input = `
*/
 * Hello, World
/*
package mypackage`

	// When...
	_, err := setCopyright(input, " *")

	// Then..
	assert.NotNil(t, err)
	assert.Contains(t, err.Error(), "closing comment marker found before the starting comment marker")
}

func TestCommentIsPresentAndIncludesCopyrightToBeRemoved(t *testing.T) {
	// Given..
	var input = `
/*
 * Copyright IBM is found here
 */
package mypackage`

	// When...
	output, _ := setCopyright(input, " *")

	// Then..
	assert.NotNil(t, output)
	assert.Contains(t, output, "* SPDX-License-Identifier: EPL-2.0")
	assert.NotContains(t, output, "Copyright IBM is found here")
}

func TestCommentIsPresentButDoesIncludesCopyrightToBeRemovedAndHasLeadingText(t *testing.T) {
	// Given..
	var input = `leading text
/*
 * IBM is found here
 */
package mypackage`

	// When...
	output, _ := setCopyright(input, " *")

	// Then..
	assert.NotNil(t, output)
	assert.Contains(t, output, "leading text")
	assert.Contains(t, output, "* SPDX-License-Identifier: EPL-2.0")
	assert.Contains(t, output, "IBM is found here")
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
	output, _ := setCopyright(input, " *")

	// Then..
	assert.NotNil(t, output)
	assert.Equal(t, output, input)
}

func TestReplaceOneLineCopyrightCommentSCSS_TS_TSXFile(t *testing.T) {
	// Given..
	var input = `/*Copyright contributiors of Galasa*/
package mypackage`

	// When...
	output, _ := setCopyright(input, " *")

	// Then..
	assert.NotNil(t, output)
	assert.NotContains(t, output, "/*Copyright contributiors of Galasa*/")
	assert.Contains(t, output, "* SPDX-License-Identifier: EPL-2.0")
}

func TestCopyrightCommentIsNotToBeRemoved(t *testing.T) {
	// Given..
	var input = `/*
 * Copyright contributions of Shrek
 */
package mypackage`

	// When...
	output, _ := setCopyright(input, " *")

	// Then..
	assert.NotNil(t, output)
	assert.Equal(t, output, input)
}

func TestCopyrightCommentContainsDoubleStroke(t *testing.T) {
	// Given..
	var input = `//Copyright contributors to Galasa Project
//IBM
package mypackage`

	// When...
	output, _ := setCopyright(input, " *")

	// Then..
	assert.NotNil(t, output)
	assert.NotContains(t, output, "//Copyright contributors to Galasa Project")
	assert.NotContains(t, output, "//IBM")
	assert.Contains(t, output, "* SPDX-License-Identifier: EPL-2.0")
}

func TestCopyrightCommentContainsMultilineDoubleStroke(t *testing.T) {
	// Given..
	var input = `//
//Copyright contributors to Galasa Project
//
package mypackage`

	// When...
	output, _ := setCopyright(input, " *")

	// Then..
	assert.NotNil(t, output)
	assert.NotContains(t, output, "//Copyright contributors to Galasa Project")
	assert.NotContains(t, output, "//")
	assert.Contains(t, output, "* SPDX-License-Identifier: EPL-2.0")
}

func TestCopyrightCommentContainsDoubleStrokeWithLeadingText(t *testing.T) {
	// Given..
	var input = `leading text here
//Copyright contributors to Galasa Project
//copyright of IBM
//

//don't remove me!
package mypackage`

	// When...
	output, _ := setCopyright(input, " *")

	// Then..
	assert.NotNil(t, output)
	assert.NotContains(t, output, "//Copyright contributors to Galasa Project")
	assert.NotContains(t, output, "//copyright of IBM")
	assert.Contains(t, output, "leading text here")
	assert.Contains(t, output, "//don't remove me!")
	assert.Contains(t, output, "* SPDX-License-Identifier: EPL-2.0")
}

func TestNonCopyrightCommentContainsDoubleStroke(t *testing.T) {
	// Given..
	var input = `leading text here
//Copyright contributors to Shrek
//
package mypackage`

	// When...
	output, _ := setCopyright(input, " *")

	// Then..
	assert.NotNil(t, output)
	assert.Contains(t, output, "//Copyright contributors to Shrek")
	assert.Contains(t, output, "leading text here")
	assert.NotContains(t, output, "* SPDX-License-Identifier: EPL-2.0")
}

func TestRemoveSingleLineCopyrightCommentDoubleStroke(t *testing.T) {
	// Given..
	var input = `leading text here
//Copyright contributors to Galasa

//don't remove me!
package mypackage`

	// When...
	output, _ := setCopyright(input, " *")

	// Then..
	assert.NotNil(t, output)
	assert.NotContains(t, output, "//Copyright contributors to Galasa")
	assert.Contains(t, output, "//don't remove me!")
	assert.Contains(t, output, "* SPDX-License-Identifier: EPL-2.0")
}

func TestRemovesCopyrightCommentAndLeavesFollowingCommentUntouchedDoubleStroke(t *testing.T) {
	// Given..
	var input = `leading text here
//Copyright contributors to Galasa
//

//don't remove me!
package mypackage`

	// When...
	output, _ := setCopyright(input, " *")

	// Then..
	assert.NotNil(t, output)
	assert.NotContains(t, output, "//Copyright contributors to Galasa")
	assert.Contains(t, output, "//don't remove me!")
	assert.Contains(t, output, "* SPDX-License-Identifier: EPL-2.0")
}

func TestWholeFileIsACopyrightCommentToBeReplacedDoubleStroke(t *testing.T) {
	// Given..
	var input = `//
//Copyright contributors to Galasa
//
//remove me!`

	// When...
	output, _ := setCopyright(input, " *")

	// Then..
	assert.NotNil(t, output)
	assert.NotContains(t, output, "//Copyright contributors to Galasa")
	assert.NotContains(t, output, "//remove me!")
	assert.Contains(t, output, "* SPDX-License-Identifier: EPL-2.0")
}

func TestWholeFileContainsCommentsWithACopyrightCommentToBeReplacesDoubleStroke(t *testing.T) {
	// Given..
	var input = `//
//Copyright contributors to Galasa
//

//don't remove me!`

	// When...
	output, _ := setCopyright(input, " *")

	// Then..
	assert.NotNil(t, output)
	assert.NotContains(t, output, "//Copyright contributors to Galasa")
	assert.Contains(t, output, "//don't remove me!")
	assert.Contains(t, output, "* SPDX-License-Identifier: EPL-2.0")
}

func TestReplaceOneLineCopyrightHashCommentYaml(t *testing.T) {
	// Given..
	var input = `# Copyright contributors to the Galasa project
apiVersion: v1
kind: PersistentVolumeClaim
metadata:`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	assert.NotContains(t, output, "# Copyright contributors to the Galasa project\napiVersion:")
	assert.Contains(t, output, "# SPDX-License-Identifier: EPL-2.0")
	assert.Contains(t, output, "apiVersion: v1\nkind: PersistentVolumeClaim")
	assert.Equal(t, 1, strings.Count(output, "Copyright contributors"), "Repeated")
}

func TestReplaceMultipleLineCopyrightWithLeadingAndEndingHashYaml(t *testing.T) {
	// Given..
	var input = `#
# Copyright contributors to the Galasa project
# Property of IBM
#

apiVersion: v1
kind: PersistentVolumeClaim
metadata:`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	assert.NotContains(t, output, "# Copyright contributors to the Galasa project\n# Property")
	assert.NotContains(t, output, "Property of IBM")
	assert.Contains(t, output, "# SPDX-License-Identifier: EPL-2.0")
	assert.Contains(t, output, "apiVersion: v1\nkind: PersistentVolumeClaim")
}

func TestReplaceSingleLineCopyrightWithLeadingAndEndingHashYaml(t *testing.T) {
	// Given..
	var input = `#
# Copyright contributors to the Galasa project
#
apiVersion: v1
kind: PersistentVolumeClaim
metadata:`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	assert.NotContains(t, output, "# Copyright contributors to the Galasa project\napiVersion:")
	assert.NotContains(t, output, "Property of IBM")
	assert.Contains(t, output, "# SPDX-License-Identifier: EPL-2.0")
	assert.Contains(t, output, "apiVersion: v1\nkind: PersistentVolumeClaim")

}

func TestReplaceMultipleLineCopyrightCommentWithoutEndingHashYaml(t *testing.T) {
	// Given..
	var input = `#
# Copyright contributors to the Galasa project
# Property of IBM

apiVersion: v1
kind: PersistentVolumeClaim
metadata:`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	assert.NotContains(t, output, "IBM")
	assert.Contains(t, output, "Copyright contributors to the Galasa project")
	assert.Contains(t, output, "# SPDX-License-Identifier: EPL-2.0")
	assert.Contains(t, output, "apiVersion: v1\nkind: PersistentVolumeClaim")
	assert.Equal(t, 1, strings.Count(output, "Copyright contributors"), "Repeated")
}

func TestReplaceMultipleLineCopyrightCommentWithoutLeadingAndEndingHashYaml(t *testing.T) {
	// Given..
	var input = `# Copyright contributors to the Galasa project
# Property of IBM

apiVersion: v1
kind: PersistentVolumeClaim
metadata:`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	assert.NotContains(t, output, "# Copyright contributors to the Galasa project\napiVersion:")
	assert.NotContains(t, output, "Property of IBM")
	assert.Contains(t, output, "# SPDX-License-Identifier: EPL-2.0")
	assert.Contains(t, output, "apiVersion: v1\nkind: PersistentVolumeClaim")
	assert.Equal(t, 1, strings.Count(output, "Copyright contributors"), "Repeated")
}

func TestReplaceCopyrightCommentAtStartOfFileWithLeadingHashButNoOtherCommentsYaml(t *testing.T) {
	// Given..
	var input = `#
Copyright contributors to the Galasa project
apiVersion: v1
kind: PersistentVolumeClaim
metadata:`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	assert.NotContains(t, output, "# Copyright contributors to the Galasa project\napiVersion:")
	assert.Contains(t, output, "# SPDX-License-Identifier: EPL-2.0")
	assert.Contains(t, output, "apiVersion: v1\nkind: PersistentVolumeClaim")
	assert.Equal(t, 2, strings.Count(output, "Copyright"), "Repeated")
}

func TestAddCopyrightWhereThereIsNoneInYamlFile(t *testing.T) {
	// Given..
	var input = `apiVersion: v1
kind: PersistentVolumeClaim
metadata:`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	assert.NotContains(t, output, "# Copyright contributors to the Galasa project\napiVersion:")
	assert.Contains(t, output, "# SPDX-License-Identifier: EPL-2.0")
	assert.Contains(t, output, "apiVersion: v1\nkind: PersistentVolumeClaim")
}

func TestDoesNotIncludeCopyrightToBeRemovedButHasLeadingTextYaml(t *testing.T) {
	// Given..
	var input = `leading text
# IBM is found here

package mypackage`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	assert.Contains(t, output, "leading text")
	assert.Contains(t, output, "# SPDX-License-Identifier: EPL-2.0")
	assert.Contains(t, output, "IBM is found here")
}

func TestIncludesCopyrightToBeRemovedButHasLeadingTextHashYaml(t *testing.T) {
	// Given..
	var input = `leading text
# Copyright IBM is found here

package mypackage`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	assert.Contains(t, output, "leading text")
	assert.NotContains(t, output, "IBM is found here Copyright")
	if !strings.HasPrefix(output, `#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#`) {
		assert.Fail(t, "Copyright statement is not at the start of the output. output:\n%s", output)
	}

}

func TestAddCopyrightCommentToStartWheretThereAreNoCommentsTextYaml(t *testing.T) {
	// Given..
	var input = `leading text

package mypackage`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	assert.Contains(t, output, "leading text")
	assert.NotContains(t, output, "IBM is found here Copyright")
	if !strings.HasPrefix(output, `#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#`) {
		assert.Fail(t, "Copyright statement is not at the start of the output. output:\n%s", output)
	}

}

func TestOnlyHasCommentsAndNoneToBeRemovedYaml(t *testing.T) {
	// Given..
	var input = `#leading text

#package mypackage`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	assert.Contains(t, output, "#leading text")
	assert.Contains(t, output, "#package mypackage")
	if !strings.HasPrefix(output, `#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#`) {
		assert.Fail(t, "Copyright statement is not at the start of the output. output:\n%s", output)
	}
}
func TestWholeContentIsACommentWithCopyrightToBeRemovedYaml(t *testing.T) {
	// Given..
	var input = `#Copyright and IBM
#
#package mypackage`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	assert.NotContains(t, output, "Copyright and IBM")
	assert.NotContains(t, output, "#package mypackage")
	if !strings.HasPrefix(output, `#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#`) {
		assert.Fail(t, "Copyright statement is not at the start of the output. output:\n%s", output)
	}
}

func TestWholeContentIsACommentNoCopyrightToBeRemovedYaml(t *testing.T) {
	// Given..
	var input = `#sgdg
#
#package mypackage`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	assert.Contains(t, output, "#package mypackage")
	if !strings.HasPrefix(output, `#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#`) {
		assert.Fail(t, "Copyright statement is not at the start of the output. output:\n%s", output)
	}
}

func TestOnlyHasCommentsAndCopyrightCommentToBeRemovedYaml(t *testing.T) {
	// Given..
	var input = `#Copyright and IBM

#package mypackage`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	assert.NotContains(t, output, "Copyright and IBM")
	assert.Contains(t, output, "#package mypackage")
	if !strings.HasPrefix(output, `#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#`) {
		assert.Fail(t, "Copyright statement is not at the start of the output. output:\n%s", output)
	}
}

func TestSpaceAtStartOfFileWIthCopyrightHashCommentToBeRemovedYaml(t *testing.T) {
	// Given..
	var input = `
#Copyright and IBM

#package mypackage`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	assert.NotContains(t, output, "Copyright and IBM")
	assert.Contains(t, output, "package mypackage")
	assert.Contains(t, output, "# SPDX-License-Identifier: EPL-2.0")
}

func TestSingleCopyrightCommentToBeRemovedWithLeadingAndClosingHashYaml(t *testing.T) {
	// Given..
	var input = `#
# Copyright contributors to the Galasa project 
#

apiVersion: apps/v1`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	assert.Contains(t, output, "\n\napiVersion")
	assert.Contains(t, output, "# SPDX-License-Identifier: EPL-2.0")
}

func TestCopyrightCommentIsNotToBeRemovedYaml(t *testing.T) {
	// Given..
	var input = `#
# Copyright contributions of Shrek
#
apiVersion: apps/v1`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	assert.Equal(t, output, input)
}

func TestCopyrightCommentNeedsNoChangeYaml(t *testing.T) {
	// Given..
	var input = `#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#

apiVersion: galasa.dev/v1alpha
kind: Release
metadata:
name: galasa-release

managers:
bundles:

#
# Manager
#
	`
	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	assert.Equal(t, output, input)
}

func TestAddCopyrightCommentWithSpaceBeforeNextComment(t *testing.T) {
	// Given..
	var input = `#where does this?
apiVersion: galasa.dev/v1alpha
kind: Release
metadata:
name: galasa-release
	`
	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	assert.Contains(t, output, "#where does this?\napiVersion")
}

func TestAddCopyrightWhenNoOtherCommentIsPresentYaml(t *testing.T) {
	// Given..
	var input = `apiVersion: v1
kind: PersistentVolumeClaim
metadata:
name: galasa-build-source-pvc
namespace: tekton
	spec:
	apiVersion: v1
	kind: PersistentVolumeClaim
	metadata:
	name: galasa-build-source-pvc
	namespace: tekton
	spec:`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	if !strings.HasPrefix(output, `#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#`) {
		assert.Fail(t, "Copyright statement is absent", output)
	}
	assert.Contains(t, output, "apiVersion: v1\nkind")
}

func TestAddCopyrightWhereThereAreMultipleNonCopyrightHashCommentInFileYaml(t *testing.T) {
	// Given..
	var input = `apiVersion: v1
kind: ConfigMap
metadata:
name: argocd-cm
namespace: argocd
labels:
	app.kubernetes.io/name: argocd-cm
	app.kubernetes.io/part-of: argocd
data:
	url: https://argocd.galasa.dev
#
#
#
accounts.galasa: "apiKey,login"
accounts.galasa.enabled: "true"
#
#
#`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	if !strings.HasPrefix(output, `#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#`) {
		assert.Fail(t, "Copyright statement is absent", output)
	}
	assert.Contains(t, output, `data:
	url: https://argocd.galasa.dev
#
#
#`)
	assert.Contains(t, output, "apiVersion: v1\nkind")
}

func TestAddCopyrightWhenCommentNotToBeReplacedYaml(t *testing.T) {
	// Given..
	var input = `#!/bin/bash

#--------------------------------------------------------------------------
#
# Objective: Set environment variables for external ecosystem services
#
#--------------------------------------------------------------------------

#
# Functions`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	if !strings.HasPrefix(output, "#!/bin/bash") {
		assert.Fail(t, "Copyright statement is absent", output)
	}
	assert.Contains(t, output, `#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#`)
	assert.Contains(t, output, `#--------------------------------------------------------------------------
#`)
}

func TestAddCopyrightWhenNoOtherCommentIsPresentBashScript(t *testing.T) {
	// Given..
	var input = `#!/usr/bin/env bash

apiVersion: apps/v1`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	if !strings.HasPrefix(output, `#!/usr/bin/env bash`) {
		assert.Fail(t, "Bash Script must start with '#!/usr/bin/env bash'. output:\n%s", output)
	}
	assert.Contains(t, output, `#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#`)
	assert.Contains(t, output, "apiVersion: apps/v1")
}

func TestCommentIsPresentButDoesNotContainCopyrightBashScript(t *testing.T) {
	// Given..
	var input = `#!/usr/bin/env bash

#what is this info here?
apiVersion: apps/v1`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	if !strings.HasPrefix(output, `#!/usr/bin/env bash`) {
		assert.Fail(t, "Bash Script must start with '#!/usr/bin/env bash'. output:\n%s", output)
	}
	assert.Contains(t, output, `#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#`)
	assert.Contains(t, output, "#what is this info here?")
	assert.Contains(t, output, "apiVersion: apps/v1")
}

func TestReplaceCopyrightBashScript(t *testing.T) {
	// Given..
	var input = `#!/usr/bin/env bash

#Copyright of IBM
#and Galasa
apiVersion: apps/v1`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	if !strings.HasPrefix(output, `#!/usr/bin/env bash`) {
		assert.Fail(t, "Bash Script must start with '#!/usr/bin/env bash'. output:\n%s", output)
	}
	assert.Contains(t, output, `#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#`)
	assert.Contains(t, output, "apiVersion: apps/v1")
}

func TestReplaceCopyrightCommentBashScript(t *testing.T) {
	// Given..
	var input = `#!/usr/bin/env bash
#Copyright of IBM
#and Galasa
apiVersion: apps/v1`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	if !strings.HasPrefix(output, `#!/usr/bin/env bash`) {
		assert.Fail(t, "Bash Script must start with '#!/usr/bin/env bash'. output:\n%s", output)
	}
	assert.Contains(t, output, `#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#`)
	assert.Contains(t, output, "apiVersion: apps/v1")
}

func TestReplaceCopyrightWithMultipleNewLinesBashScript(t *testing.T) {
	// Given..
	var input = `#!/usr/bin/env bash 


#Copyright of IBM
#and Galasa
apiVersion: apps/v1`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	if !strings.HasPrefix(output, `#!/usr/bin/env bash`) {
		assert.Fail(t, "Bash Script must start with '#!/usr/bin/env bash'. output:\n%s", output)
	}
	assert.Contains(t, output, `#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#`)
	assert.Contains(t, output, "apiVersion: apps/v1")
}

func TestReplaceCopyrightWithLeadingHashBashScript(t *testing.T) {
	// Given..
	var input = `#!/usr/bin/env bash
#
#Copyright of IBM
#and Galasa
apiVersion: apps/v1`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	if !strings.HasPrefix(output, `#!/usr/bin/env bash`) {
		assert.Fail(t, "Bash Script must start with '#!/usr/bin/env bash'. output:\n%s", output)
	}
	assert.Contains(t, output, `#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#`)
	assert.Contains(t, output, "apiVersion: apps/v1")
}

func TestCommentDoesNotContainCopyrightAndHasLeadingTextBashScript(t *testing.T) {
	// Given..
	var input = `#!/usr/bin/env bash

hello world!
#what copyright info is this?
apiVersion: apps/v1`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	if !strings.HasPrefix(output, `#!/usr/bin/env bash`) {
		assert.Fail(t, "Bash Script must start with '#!/usr/bin/env bash'. output:\n%s", output)
	}
	assert.Contains(t, output, `#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#`)
	assert.Contains(t, output, "#what copyright info is this?")
	assert.Contains(t, output, "apiVersion: apps/v1")
}

func TestNoCopyrightChangeNeededBashScript(t *testing.T) {
	// Given..
	var input = `#!/usr/bin/env bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#
apiVersion: apps/v1`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	if !strings.HasPrefix(output, `#!/usr/bin/env bash`) {
		assert.Fail(t, "Bash Script must start with '#!/usr/bin/env bash'. output:\n%s", output)
	}
	assert.Contains(t, output, `#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#`)
	assert.Contains(t, output, "apiVersion: apps/v1")
}

func TestCopyrightCommentIsNotToBeRemovedBashScript(t *testing.T) {
	// Given..
	var input = `#! /usr/bin/env bash
# Copyright contributions of Shrek
#
apiVersion: apps/v1`

	// When...
	output, _ := setCopyright(input, "#")

	// Then..
	assert.NotNil(t, output)
	assert.Equal(t, output, input)
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

func TestAppliesChangesToYamlFileInFolder(t *testing.T) {
	fs := files.NewMockFileSystem()
	fs.MkdirAll("/my/folder/")
	fs.WriteTextFile("/my/folder/myYamlFile.yaml", `Yaml source code`)

	err := processFolder(fs, "/my/folder/")

	assert.Nil(t, err)

	contents, err := fs.ReadTextFile("/my/folder/myYamlFile.yaml")
	assert.Nil(t, err)
	assert.Contains(t, contents, "Yaml source code")
	assert.Contains(t, contents, "Copyright")
}

func TestAppliesChangesToBashScriptFileInFolder(t *testing.T) {
	fs := files.NewMockFileSystem()
	fs.MkdirAll("/my/folder/")
	fs.WriteTextFile("/my/folder/myBashFile.sh", `Bash source code`)

	err := processFolder(fs, "/my/folder/")

	assert.Nil(t, err)

	contents, err := fs.ReadTextFile("/my/folder/myBashFile.sh")
	assert.Nil(t, err)
	assert.Contains(t, contents, "Bash source code")
	assert.Contains(t, contents, "Copyright")
}
