# DNS

The Linux Foundation owns the `galasa.dev` DNS domain on behalf of the Galasa project.




These are the settings currently held in the DNS table currently.

## Change history:
- Ticket to set up the initial DNS records: https://jira.linuxfoundation.org/plugins/servlet/desk/portal/2/IT-27904

## Current snapshot of the records we have configured:

| Record Type | subdomain | target | Notes |
|-------------|-----------|--------|-------|
| A | argocd.galasa.dev | | 169.50.192.70 ||
| A | argocd-b.galasa.dev | 169.50.192.70 ||
| A | copyright.galasa.dev | 169.50.192.70 ||
| A | development.galasa.dev | 169.50.192.70 ||
| A | dex.galasa.dev | 169.50.192.70 | What is this one ? |
| A | docker.galasa.dev | 169.50.192.70 | Very old. Can be deleted. |
| A | galasa-ecosystem1.galasa.dev | 169.50.192.70 ||
| A | harbor.galasa.dev | 169.50.192.70 | old. Can be deleted. |
| A | harbor-b.galasa.dev | 169.50.192.70 | old. Can be deleted. |
| A | hobbit.galasa.dev | 169.50.192.70 | old. Can be deleted. |
| A | javadoc.galasa.dev | 169.50.192.70 ||
| A | javadoc-snapshot.galasa.dev | 169.50.192.70 ||
| A | nexus.galasa.dev | 169.50.192.70 | old. Can be deleted |
| A | nexus-planb.galasa.dev | 169.50.192.70 | old. Can be deleted |
| A | resources.galasa.dev | 169.50.192.70 ||
| A | rest.galasa.dev | 169.50.192.70 ||
| A | sonarqube.galasa.dev | 169.50.192.70 | old. Can be deleted |
| A | triggers.galasa.dev | 169.50.192.70 ||
| ALIAS | galasa.dev | galasa-dev.github.io | Main documentation site. See galasa-dev/galasa-docs repo |
| CNAME | www.galasa.dev | galasa-dev.github.io | Main documentation site. See galasa-dev/galasa-docs repo |
| CNAME | vnext.galasa.dev | galasa-dev.github.io | Preview of documentation. See galasa-dev/galasa-docs-preview repo |

