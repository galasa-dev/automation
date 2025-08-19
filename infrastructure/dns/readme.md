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
| A | galasa2.galasa.dev | 169.50.192.66 | Created to try out cert-manager for a Galasa service. Maps to the IP of the ingress-nginx-controller LoadBalancer in the ingress-nginx namespace |
| A | galasa-ecosystem1.galasa.dev | 169.50.192.70 ||
| A | javadoc.galasa.dev | URL redirect to https://galasa.dev/docs/reference/javadoc/ | |
| A | javadoc-snapshot.galasa.dev | 169.50.192.70 ||
| A | rest.galasa.dev | 169.50.192.70 ||
| A | triggers.galasa.dev | 169.50.192.70 ||
| ALIAS | galasa.dev | galasa-dev.github.io | Main documentation site. See galasa-dev/galasa-docs repo |
| CNAME | www.galasa.dev | galasa-dev.github.io | Main documentation site. See galasa-dev/galasa-docs repo |
| CNAME | vnext.galasa.dev | galasa-dev.github.io | Preview of documentation. See galasa-dev/galasa-docs-preview repo |
| URL | resources.galasa.dev | URL redirect to https://github.com/galasa-dev/isolated/releases ||

As of 9th July, the DNS records look like this:
```
$ORIGIN galasa.dev.
$TTL 1h
galasa.dev. 3600 IN SOA ns1.dnsimple.com. admin.dnsimple.com. 1736533337 86400 7200 604800 300
galasa.dev. 3600 IN NS ns1.dnsimple.com.
galasa.dev. 3600 IN NS ns2.dnsimple.com.
galasa.dev. 3600 IN NS ns3.dnsimple.com.
galasa.dev. 3600 IN NS ns4.dnsimple.com.
argocd-b.galasa.dev. 60 IN A 169.50.192.70
argocd.galasa.dev. 60 IN A 169.50.192.70
copyright.galasa.dev. 60 IN A 169.50.192.70
development.galasa.dev. 60 IN A 169.50.192.70
galasa-ecosystem1.galasa.dev. 60 IN A 169.50.192.70
rest.galasa.dev. 60 IN A 169.50.192.70
triggers.galasa.dev. 60 IN A 169.50.192.70
vnext.galasa.dev. 600 IN CNAME galasa-dev.github.io.
galasa.dev. 3600 IN TXT "forward-email-site-verification=dgUt5B5ttd"
galasa.dev. 3600 IN MX 10 mx1.forwardemail.net.
galasa.dev. 3600 IN MX 10 mx2.forwardemail.net.
_acme-challenge.galasa.dev. 60 IN TXT "30K3xObf-mVa_KpFPF2vbxi55QinL96LgdtxE7J-BYo"
_acme-challenge.galasa.dev. 60 IN TXT "rhxkoqbYmUGGRPI8zZoLAeYk7sTsi_KjRfsxG4WK67Y"
; galasa.dev. 60 IN ALIAS galasa-dev.github.io.
www.galasa.dev. 60 IN CNAME galasa-dev.github.io.
_acme-challenge.javadoc.galasa.dev. 1 IN TXT "FUVCa09SxH_DtVTFoV9f3RRQktj5vJm7yimT7BzZsJs"
; javadoc.galasa.dev. 60 IN URL https://galasa.dev/docs/reference/javadoc/
```