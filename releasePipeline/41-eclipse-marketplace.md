# Update the Eclipse Marketplace

1. Get the credentials for the Eclipse marketplace from the IBM Cloud Secrets Manager. The secret name has the word 'eclipse' in it. (For some reason, the IBM Cloud CLI command that is provided by IBM Cloud to get the credentials is incomplete and requires `--secret-type username_password` to be appended to it)
1. Logon to https://marketplace.eclipse.org/ using the credentials.
2. Locate the Galasa plugin https://marketplace.eclipse.org/content/galasa/edit and edit.
3. Update the Solution Version and Save and Save.
4. Check the released supported eclipse versions, removing any versions that we know are unsupported.