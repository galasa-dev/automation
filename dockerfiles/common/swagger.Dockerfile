FROM ghcr.io/galasa-dev/openjdk:11

RUN mkdir /opt/swagger
RUN curl -L https://repo1.maven.org/maven2/io/swagger/codegen/v3/swagger-codegen-cli/3.0.41/swagger-codegen-cli-3.0.41.jar -o /opt/swagger/swagger-codegen-cli.jar