FROM ghcr.io/galasa-dev/httpd:alpine

RUN rm -v /usr/local/apache2/htdocs/*
COPY dockerfiles/httpdconf/base-httpd.conf /usr/local/apache2/conf/httpd.conf