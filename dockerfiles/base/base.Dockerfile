FROM ghcr.io/galasa-dev/httpd:alpine

# Mend scans reported vulnerabilities with perl, which gets installed in the httpd image.
# perl is an optional requirement for httpd, so we're removing it here.
RUN rm -v /usr/local/apache2/htdocs/* && apk --purge del perl
COPY dockerfiles/httpdconf/base-httpd.conf /usr/local/apache2/conf/httpd.conf