
FROM ghcr.io/galasa-dev/gradle:8.9-jdk17

COPY ibmroot.pem  /etc/ssl/certs/ibmroot.pem
COPY ibminter.pem /etc/ssl/certs/ibminter.pem
RUN  cat /etc/ssl/certs/ibmroot.pem >> /etc/ssl/certs/ca-certificates.crt
RUN  cat /etc/ssl/certs/ibminter.pem >> /etc/ssl/certs/ca-certificates.crt

USER root

COPY carootcert.der $JAVA_HOME/lib/security
COPY caintermediatecert.der $JAVA_HOME/lib/security

RUN \
    cd $JAVA_HOME/lib/security \
    && keytool -keystore cacerts -storepass changeit -noprompt -trustcacerts -importcert -alias ibmca -file carootcert.der \
    && keytool -keystore cacerts -storepass changeit -noprompt -trustcacerts -importcert -alias ibminter -file caintermediatecert.der