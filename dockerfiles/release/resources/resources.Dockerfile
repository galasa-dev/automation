FROM ghcr.io/galasa-dev/httpd:alpine
ARG branch
ARG version

RUN rm -v /usr/local/apache2/htdocs/*
COPY httpd.conf /usr/local/apache2/conf/httpd.conf

RUN echo ${version} - ${branch}

RUN wget --no-check-certificate -q https://development.galasa.dev/${branch}/maven-repo/isolated/dev/galasa/galasa-isolated/${version}/galasa-isolated-${version}.zip -O /usr/local/apache2/htdocs/isolated-${version}.zip
RUN ln -sf /usr/local/apache2/htdocs/isolated-${version}.zip /usr/local/apache2/htdocs/isolated.zip