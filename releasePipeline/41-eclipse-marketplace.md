# Update the Eclipse Marketplace

1. Get the credentials for the Eclipse marketplace from the IBM Cloud Secrets Manager. The secret name has the word 'eclipse' in it. ('buildgalasa-eclipse-foundation')
1.1 Make sure you have the IBM cloud CLI installed.
1.2 Make sure you have the IBM Cloud secrets manager plugin installed if you've not got it already. `ibmcloud plugin install secrets-manager`
1.3 This snippet gets the secret directly... `ibmcloud secrets-manager secret --id "5d027bd1-700a-5c59-fd14-c6cd92996680" --service-url https://7ff484c0-fe69-44c5-8359-23423cae76f6.eu-gb.secrets-manager.appdomain.cloud`
1.4 You will see it has a `username` and `password` field, which you need to use next...

2. Logon to https://marketplace.eclipse.org/ using the credentials.
2.1 Note: The login panel may ask for an email address, but it still accepts a userid...
3. Locate the Galasa plugin https://marketplace.eclipse.org/content/galasa/edit and edit.
4. Update the Solution Version and Save and Save.
5. Check the released supported eclipse versions, removing any versions that we know are unsupported. Save.