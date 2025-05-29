FROM ghcr.io/galasa-dev/openjdk:11

RUN mkdir /opt/openapi
RUN curl -L https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/6.6.0/openapi-generator-cli-6.6.0.jar -o /opt/openapi/openapi-generator-cli.jar