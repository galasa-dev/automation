/*
 * Copyright contributors to the Galasa project
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package files

import (
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestTildaExpansionWhenFilenameBlankReturnsBlank(t *testing.T) {
	pathIn := ""
	fs := NewMockFileSystem()
	pathGotBack, err := TildaExpansion(fs, pathIn)
	assert.Nil(t, err)
	assert.Empty(t, pathGotBack)
}

func TestTildaExpansionWhenFilenameNormalBlankReturnsBlank(t *testing.T) {
	pathIn := "normal"
	fs := NewMockFileSystem()
	pathGotBack, err := TildaExpansion(fs, pathIn)
	assert.Nil(t, err)
	assert.Equal(t, pathGotBack, "normal")
}

func TestCanCreateTempFolder(t *testing.T) {
	fs := NewOSFileSystem()
	path, err := fs.MkTempDir()
	assert.Nil(t, err)
	defer func() {
		fs.DeleteDir(path)
	}()
	assert.NotNil(t, path)
}

func TestCanWriteAndReadTempTextFile(t *testing.T) {
	fs := NewOSFileSystem()
	tempFolderPath, _ := fs.MkTempDir()
	defer func() {
		fs.DeleteDir(tempFolderPath)
	}()
	textFilePath := tempFolderPath + fs.GetFilePathSeparator() + "textFile.txt"
	content := "hello\nworld\n"
	err := fs.WriteTextFile(textFilePath, content)
	assert.Nil(t, err)
	textGotBack, err := fs.ReadTextFile(textFilePath)
	assert.Nil(t, err)
	assert.Equal(t, content, textGotBack)
}

func TestCanDeleteFilesAndTheyGo(t *testing.T) {
	fs := NewOSFileSystem()
	tempFolderPath, _ := fs.MkTempDir()
	exists, err := fs.DirExists(tempFolderPath)
	assert.Nil(t, err)
	assert.True(t, exists)

	// Now delete it
	fs.DeleteDir((tempFolderPath))

	exists, err = fs.DirExists(tempFolderPath)
	assert.Nil(t, err)
	assert.False(t, exists)
}

func TestCanOutputWarningMessageDoesntBlowUp(t *testing.T) {
	fs := NewOSFileSystem()
	fs.OutputWarningMessage("hello")
}

func TestGetUserHomeDirReturnsSomething(t *testing.T) {
	fs := NewOSFileSystem()
	homeDirPath, err := fs.GetUserHomeDirPath()
	assert.Nil(t, err)
	assert.NotEmpty(t, homeDirPath)
	assert.True(t, strings.HasPrefix(homeDirPath, fs.GetFilePathSeparator()))
}

func TestMkAllDirCreatesNestOfFoldersOk(t *testing.T) {
	fs := NewOSFileSystem()
	tempFolderPath, _ := fs.MkTempDir()
	defer func() {
		fs.DeleteDir(tempFolderPath)
	}()
	nestedFolderPath := tempFolderPath + fs.GetFilePathSeparator() +
		"a" + fs.GetFilePathSeparator() + "b"

	// When we create the next of folders.
	err := fs.MkdirAll(nestedFolderPath)
	assert.Nil(t, err)

	exists, err := fs.DirExists(nestedFolderPath)
	assert.Nil(t, err)
	assert.True(t, exists)

}

func TestCreatedFileExists(t *testing.T) {
	fs := NewOSFileSystem()
	tempFolderPath, _ := fs.MkTempDir()
	defer func() {
		fs.DeleteDir(tempFolderPath)
	}()
	textFilePath := tempFolderPath + fs.GetFilePathSeparator() + "textFile.txt"
	content := "hello\nworld\n"
	err := fs.WriteTextFile(textFilePath, content)
	assert.Nil(t, err)

	// When we check for the file's existence...
	exists, err := fs.Exists(textFilePath)
	assert.Nil(t, err)
	assert.True(t, exists)

	// Now when we delete it
	fs.DeleteDir(tempFolderPath)

	exists, err = fs.Exists(textFilePath)
	assert.Nil(t, err)
	assert.False(t, exists)

}

func TestCanWalkFolderTree(t *testing.T) {
	var err error
	fs := NewOSFileSystem()

	// Create a temporary file system
	tempFolderPath, _ := fs.MkTempDir()
	defer func() {
		fs.DeleteDir(tempFolderPath)
	}()

	// Write the text file 1
	textFilePath1 := tempFolderPath + fs.GetFilePathSeparator() + "textFile1.txt"
	content1 := "hello\nworld\n"
	err = fs.WriteTextFile(textFilePath1, content1)
	assert.Nil(t, err)

	// Write the text file 2
	textFilePath2 := tempFolderPath + fs.GetFilePathSeparator() + "textFile2.txt"
	content2 := "hello\nworld\n"
	err = fs.WriteTextFile(textFilePath2, content2)
	assert.Nil(t, err)

	// Walk the folder.
	filePaths, err := fs.GetAllFilesInFolder(tempFolderPath)

	assert.Nil(t, err)
	assert.Equal(t, len(filePaths), 2)
	assert.Equal(t, filePaths[0], textFilePath1)
	assert.Equal(t, filePaths[1], textFilePath2)
}
