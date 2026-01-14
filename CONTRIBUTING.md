# Contributing

All Galasa repositories share a common method of how to contribute. You must either:
- Become an approved committer
- Fork the code and submit a Pull Request.

## Become an approved committer

This means you are trusted with the responsibility for not breaking the code, so your ID appears as a member of the [code-committers team](https://github.com/orgs/galasa-dev/teams/code-committers) in the [galasa-dev GitHub organisation](https://github.com/galasa-dev). With this authority, you are able to create a branch on any of the repositories. Pull requests for any of these branches are approved for building automatically. If you commit to a branch on a Pull Request from a fork, your change will also be approved for building.

## Fork the code and submit a Pull Request

You are not an approved committer on the project, so when you submit a Pull Request, the changes will need to be approved. Any of the other approved committers will then have to review your changes, and check that no malicious code is being added, and that the code passes inspection. An approved committer will have to approve the GitHub Actions workflow to run, and this will cause a build of the code to be performed and build checks/tests carried out.

If the code in the Pull Request is updated, you will need to go through the procedure again in order to get approval for another build attempt, and so on.

Once built, a trusted committer may merge the change into the codebase once the build checks are complete, and all discussions on the Pull Request have been resolved.

## Contributing to other repositories

The Contributor's Guide for contributing to the main Galasa repository can be found [here](https://github.com/galasa-dev/galasa/blob/main/CONTRIBUTING.md).