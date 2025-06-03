# Publish to Maven Central with the Maven Central Publisher Portal

1. Logon to the [Maven Central Publisher Portal](https://central.sonatype.com/).
    - Use the 'login-username' and 'login-password' from 'central-publisher-portal' in Vault or the username and password from 'central-publisher-portal-credentials' in IBM Cloud Secrets Manager.
1. Click the account icon in the top right, and then from the dropdown, click 'View Deployments'. You should see a bundle called 'dev-galasa-bundle-<version>.zip'.
1. Check that all the validation checks were successful.
1. If they were unsuccessful, click 'Drop' to delete the deployment. Debug why the validation checks failed and go back to that part of the release.
1. If they were successful, click 'Publish' on the bundle to publish it to Maven Central.
