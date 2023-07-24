/*
 * Copyright contributors to the Galasa project
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package files

import (
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	pathUtils "path"
	"runtime"
)

// FileSystem is a thin interface layer above the os package which can be mocked out
type FileSystem interface {
	// MkdirAll creates all folders in the file system if they don't already exist.
	MkdirAll(targetFolderPath string) error
	ReadTextFile(filePath string) (string, error)
	WriteTextFile(targetFilePath string, desiredContents string) error
	WriteBinaryFile(targetFilePath string, desiredContents []byte) error
	Exists(path string) (bool, error)
	DirExists(path string) (bool, error)
	GetUserHomeDirPath() (string, error)
	OutputWarningMessage(string) error
	MkTempDir() (string, error)
	DeleteDir(path string)

	// Creates a file in the file system if it can.
	Create(path string) (io.Writer, error)

	// Returns the normal extension used for executable files.
	// ie: The .exe suffix in windows, or "" in unix-like systems.
	GetExecutableExtension() string

	// GetPathSeparator returns the file path separator specific
	// to this operating system.
	GetFilePathSeparator() string

	// Get a list of all the paths to files in the specified folder.
	GetAllFilesInFolder(folderPath string) ([]string, error)
}

// TildaExpansion If a file starts with a tilda '~' character, expand it
// to the home folder of the user on this file system.
func TildaExpansion(fileSystem FileSystem, path string) (string, error) {
	var err error = nil
	if path != "" {
		if path[0] == '~' {
			var userHome string
			userHome, err = fileSystem.GetUserHomeDirPath()
			path = pathUtils.Join(userHome, path[1:])
		}
	}
	return path, err
}

//------------------------------------------------------------------------------------
// The implementation of the real os-delegating variant of the FileSystem interface
//------------------------------------------------------------------------------------

type OSFileSystem struct {
}

// NewOSFileSystem creates an implementation of the thin file system layer which delegates
// to the real os package calls.
func NewOSFileSystem() FileSystem {
	return new(OSFileSystem)
}

// ------------------------------------------------------------------------------------
// Interface methods...
// ------------------------------------------------------------------------------------

func walkFolder(path string) ([]string, error) {

	var results []string = []string{}

	_, err := os.Stat(path)
	if err != nil {
		// It's something which doesn't exist
		err = errors.New(fmt.Sprintf("Folder %s doesn't exist.", path))
	} else {
		// It exists, whatever it is.
		folder, err := os.Open(path)
		if err != nil {
			err = errors.New(fmt.Sprintf("File %s could not open.", path))
		} else {
			defer folder.Close()

			var fileStat fs.FileInfo
			fileStat, err = folder.Stat()
			if err != nil {
				err = errors.New(fmt.Sprintf("Could not get  %s doesn't exist.", path))
			} else {
				mode := fileStat.Mode()

				if mode.IsDir() {
					// It's a folder. Walk it.
					entries, err := os.ReadDir(path)
					if err != nil {
						err = errors.New(fmt.Sprintf("Could not read directory %s. Error: %s", path, err))
					} else {
						for _, entry := range entries {
							fileName := entry.Name()
							entryPath := path + "/" + fileName
							var subResults []string
							subResults, err = walkFolder(entryPath)
							if err == nil {
								results = append(results, subResults...)
							}
						}
					}
				} else {
					if mode.IsRegular() {
						// It's a regular file.
						results = append(results, path)
					}
				}
			}
		}
	}
	return results, err
}

func (osFS *OSFileSystem) GetAllFilesInFolder(path string) ([]string, error) {
	results, err := walkFolder(path)
	return results, err
}

func (osFS *OSFileSystem) Create(path string) (io.Writer, error) {
	fileWriter, err := os.Create(path)
	return fileWriter, err
}

func (osFS *OSFileSystem) GetFilePathSeparator() string {
	return string(os.PathSeparator)
}

func (osFS *OSFileSystem) GetExecutableExtension() string {
	var extension string = ""
	if runtime.GOOS == "windows" {
		extension = ".exe"
	}
	return extension
}

func (osFS *OSFileSystem) MkTempDir() (string, error) {
	const DEFAULT_TEMP_FOLDER_PATH_FOR_THIS_OS = ""
	tempFolderPath, err := os.MkdirTemp(DEFAULT_TEMP_FOLDER_PATH_FOR_THIS_OS, "galasa-*")
	return tempFolderPath, err
}

func (osFS *OSFileSystem) DeleteDir(path string) {
	os.RemoveAll(path)
}

func (osFS *OSFileSystem) MkdirAll(targetFolderPath string) error {
	err := os.MkdirAll(targetFolderPath, 0755)
	if err != nil {
		err = errors.New(fmt.Sprintf("Failed to create folder %s. Original error: %s", targetFolderPath, err.Error()))
	}
	return err
}

func (osFS *OSFileSystem) WriteBinaryFile(targetFilePath string, desiredContents []byte) error {
	err := os.WriteFile(targetFilePath, desiredContents, 0644)
	if err != nil {
		err = errors.New(fmt.Sprintf("Failed to write binary file %s. Original error: %s", targetFilePath, err.Error()))
	}
	return err
}

func (osFS *OSFileSystem) WriteTextFile(targetFilePath string, desiredContents string) error {
	bytes := []byte(desiredContents)
	err := osFS.WriteBinaryFile(targetFilePath, bytes)
	return err
}

func (*OSFileSystem) ReadTextFile(filePath string) (string, error) {
	text := ""
	bytes, err := os.ReadFile(filePath)
	if err != nil {
		err = errors.New(fmt.Sprintf("Failed to read file %s. Original error: %s", filePath, err.Error()))
	} else {
		text = string(bytes)
	}
	return text, err
}

func (*OSFileSystem) Exists(path string) (bool, error) {
	isExists := true
	_, err := os.Stat(path)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			// path/to/whatever does not exist
			isExists = false
			err = nil
		}
	}
	return isExists, err
}

func (*OSFileSystem) DirExists(path string) (bool, error) {
	isDirExists := true
	metadata, err := os.Stat(path)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			// path/to/whatever does not exist
			isDirExists = false
			err = nil
		}
	} else {
		isDirExists = metadata.IsDir()
	}
	return isDirExists, err
}

func (*OSFileSystem) GetUserHomeDirPath() (string, error) {
	dirName, err := os.UserHomeDir()
	if err != nil {
		err = errors.New(fmt.Sprintf("Failed to find user hone directory. Original error: %s", err.Error()))
	}
	return dirName, err
}

func (OSFileSystem) OutputWarningMessage(message string) error {
	_, err := os.Stderr.WriteString(message)
	return err
}
