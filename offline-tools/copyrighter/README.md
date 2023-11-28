## Copyrighter Tool
This tool checks if a file does not have a copyright comment, or if it has an undesired copyright comment, and then replaces it with the suitable copyright statement. 

The tool ensures files have a copyright comment like the one below:<br />
/*<br />
 *Copyright contributors to the Galasa project<br />
 *<br />
 *SPDX-License-Identifier: EPL-2.0<br />
 */<br />


## Files that the tool is able to process
- Files with /* */ or // type comments:<br />
    Java (.java), Go (.go), JavaScript (.js), Sass (.scss), TypeScript (.ts), TypeScript with JSX (.tsx)<br />
- Files with # type comments:<br />
    Yaml (.yaml), Bash Script (.sh)<br />

For files that the tool is unable to process, a message will be given with more information about whether the file contains a copyright statement. Eg:<br />
    `Tool not able to process a file which contains a Galasa copyright statement: <relative filepath>`


## Using the tool 

### Clone the repo to your local machine
- Clone the automation repo
- Navigate to offlinetools/copyrighter using cd in your terminal

### Building the code locally
Use the `./build-locally.sh` script to build the code.

### Applying the tool to desired directory
- Copy the full path of ./automation/offline-tools/copyrighter/bin/galasacopyrighter-darwin-arm64
- Navigate to the directory where you want to apply the copyright changes and paste the path
- Use the flag `-f, --folder <string>`, where string is the files in the folder that need transforming, to add copyright statements to the files you want.<br />
For example, to change all the files in a directy, use:<br />
    `Users/user/automation/offline-tools/copyrighter/bin/galasacopyrighter-darwin-arm64 --folder .`

 
## License
This code is under the [Eclipse Public License 2.0](https://github.com/galasa-dev/maven/blob/main/LICENSE).
