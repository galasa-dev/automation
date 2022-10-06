FROM docker.io/library/ubuntu:latest

ENV DEBIAN_FRONTEND="noninteractive" TZ="Europe/London"
RUN apt-get update && apt-get install -y unzip \
    curl \
    xz-utils \
    golang \
    make \
    python2 \
    gpg && apt-get clean && rm -rf /var/lib/apt/lists/*

# Installing Java 11
# RUN mkdir /usr/local/java
# RUN curl -L https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk11u-2021-05-07-07-34/OpenJDK11U-jdk_x64_linux_openj9_2021-05-07-07-34.tar.gz \
#       -o /usr/local/java/OpenJDK11U-jdk_x64_linux_openj9_2021-05-07-07-34.tar.gz \ 
#      && tar -zxvf /usr/local/java/OpenJDK11U-jdk_x64_linux_openj9_2021-05-07-07-34.tar.gz -C /usr/local/java \
#      && rm /usr/local/java/OpenJDK11U-jdk_x64_linux_openj9_2021-05-07-07-34.tar.gz 
# ENV JAVA_HOME=/usr/local/java/jdk-11.0.12+1
# ENV PATH=$PATH:$JAVA_HOME/bin

RUN mkdir /certs
COPY ibmca.pem /certs
COPY ibminter.pem /certs
RUN keytool -import -trustcacerts -alias ibmca -file /certs/ibmca.pem -keystore $JAVA_HOME/lib/security/cacerts -storepass changeit -noprompt
RUN keytool -import -trustcacerts -alias ibminter -file /certs/ibminter.pem -keystore $JAVA_HOME/lib/security/cacerts  -storepass changeit -noprompt

RUN  cat /certs/ibmca.pem >> /etc/ssl/certs/ca-certificates.crt
RUN  cat /certs/ibminter.pem >> /etc/ssl/certs/ca-certificates.crt

RUN update-ca-certificates
