# DNS

The Linux Foundation owns the `galasa.dev` DNS domain on behalf of the Galasa project.




These are the settings currently held in the DNS table currently.

## Change history:
- Ticket to set up the initial DNS records: https://jira.linuxfoundation.org/plugins/servlet/desk/portal/2/IT-27904

## Current snapshot of the records we have configured:

| Record Type | subdomain | target | Notes |
|-------------|-----------|--------|-------|
| A | galasa-ecosystem1.galasa.dev | 169.50.192.70 ||
| CNAME | vnext.galasa.dev | galasa-dev.github.io | Preview of documentation. See galasa-dev/galasa-docs-preview repo |
| ALIAS | galasa.dev | galasa-dev.github.io | Main documentation site. See galasa-dev/galasa-docs repo |
| CNAME | www.galasa.dev | galasa-dev.github.io | Main documentation site. See galasa-dev/galasa-docs repo |
| URL | javadoc.galasa.dev | URL redirect to https://galasa.dev/docs/reference/javadoc/ ||
| URL | resources.galasa.dev | URL redirect to https://github.com/galasa-dev/isolated/releases ||
| URL | rest.galasa.dev | URL redirect to https://galasa.dev/docs/reference/rest-api ||
| URL | www.rest.galasa.dev | URL redirect to https://galasa.dev/docs/reference/rest-api ||
| CNAME | galasa-service1.galasa.dev | c0505e90-eu-gb.lb.appdomain.cloud ||
| CNAME | argocd.galasa.dev | c0505e90-eu-gb.lb.appdomain.cloud ||
| CNAME | development.galasa.dev | c0505e90-eu-gb.lb.appdomain.cloud ||
| CNAME | copyright.galasa.dev | c0505e90-eu-gb.lb.appdomain.cloud ||
| CNAME | triggers.galasa.dev | c0505e90-eu-gb.lb.appdomain.cloud ||

As of 26th November, the DNS records look like this:
```
$ORIGIN galasa.dev.
$TTL 1h
galasa.dev. 3600 IN SOA ns1.dnsimple.com. admin.dnsimple.com. 1736533392 86400 7200 604800 300
galasa.dev. 3600 IN NS ns1.dnsimple.com.
galasa.dev. 3600 IN NS ns2.dnsimple.com.
galasa.dev. 3600 IN NS ns3.dnsimple.com.
galasa.dev. 3600 IN NS ns4.dnsimple.com.
galasa-ecosystem1.galasa.dev. 60 IN A 169.50.192.70
vnext.galasa.dev. 600 IN CNAME galasa-dev.github.io.
galasa.dev. 3600 IN TXT "forward-email-site-verification=dgUt5B5ttd"
galasa.dev. 3600 IN MX 10 mx1.forwardemail.net.
galasa.dev. 3600 IN MX 10 mx2.forwardemail.net.
_acme-challenge.galasa.dev. 60 IN TXT "30K3xObf-mVa_KpFPF2vbxi55QinL96LgdtxE7J-BYo"
_acme-challenge.galasa.dev. 60 IN TXT "rhxkoqbYmUGGRPI8zZoLAeYk7sTsi_KjRfsxG4WK67Y"
; galasa.dev. 60 IN ALIAS galasa-dev.github.io.
www.galasa.dev. 60 IN CNAME galasa-dev.github.io.
; javadoc.galasa.dev. 60 IN URL https://galasa.dev/docs/reference/javadoc/
; resources.galasa.dev. 60 IN URL https://github.com/galasa-dev/isolated/releases
_acme-challenge.galasa.dev. 60 IN TXT "vxYXQd3Wb8geJi1_S30rlrlfz9j-Jje5NaDmzwQWp9E"
; rest.galasa.dev. 60 IN URL https://galasa.dev/docs/reference/rest-api/
; www.rest.galasa.dev. 60 IN URL https://galasa.dev/docs/reference/rest-api/
galasa-service1.galasa.dev. 60 IN CNAME c0505e90-eu-gb.lb.appdomain.cloud.
argocd.galasa.dev. 60 IN CNAME c0505e90-eu-gb.lb.appdomain.cloud.
development.galasa.dev. 60 IN CNAME c0505e90-eu-gb.lb.appdomain.cloud.
copyright.galasa.dev. 60 IN CNAME c0505e90-eu-gb.lb.appdomain.cloud.
triggers.galasa.dev. 60 IN CNAME c0505e90-eu-gb.lb.appdomain.cloud.
```