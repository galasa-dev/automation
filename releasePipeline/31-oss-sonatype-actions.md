# Sonatype actions

1. Logon to https://s01.oss.sonatype.org using the credentials 'maven-creds' from Vault ('sonatype-credentials' in secrets manager)
1. Close the newly created staging repository, probably called something like galasadev-1005 (tick the box then press Close)
1. Wait for it to close and complete it's validation checks (see Activity tab)
1. Release the staging repository (tick the box then press Release)