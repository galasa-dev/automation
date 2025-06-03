# Build from the obr-maven-artefacts image which contains all the built artifacts from the build process.
FROM ghcr.io/galasa-dev/obr-maven-artefacts:release

# The version of Galasa to be released to label the bundle with.
ARG version

# Install the `zip` tool to create the bundle, and the `curl` tool to contact the Central Publisher Portal REST API.
RUN apk add --no-cache zip curl

# Go to the directory within the image that contains all the built artifacts.
WORKDIR /usr/local/apache2/htdocs

# Remove all files that we do not want to include in the bundle to publish to the Central Portal.
RUN rm extensions.githash framework.githash gradle.githash managers.githash maven.githash obr.githash wrapping.githash buildutils.githash \
    && rm -rf codecoverage

# Create the bundle by zipping up the `dev` directory which has a structure like below:
# .
# └── dev
#     └── galasa
#         ├── dev.galasa
#         │   ├── x.xx.x
RUN zip -r dev-galasa-bundle-${version}.zip dev/
