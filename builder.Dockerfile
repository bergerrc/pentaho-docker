ARG MAVEN_TAG=3.6.1-jdk-8-alpine
FROM maven:$MAVEN_TAG AS builder
LABEL author="Beeapps <contato@beeapps.com.br>"

#Prepare source-code
RUN mkdir ~/.m2
#COPY ./.m2/settings.xml .
RUN wget https://raw.githubusercontent.com/pentaho/maven-parent-poms/master/maven-support-files/settings.xml
RUN apk upgrade && \ 
    apk add --no-cache git
WORKDIR /opt
#Inform pentaho's github release or tag
ARG PENTAHO_TAG=9.2.0.0-175
RUN git clone --branch $PENTAHO_TAG https://github.com/pentaho/pentaho-platform.git

#Run Maven to create packages
WORKDIR /opt/pentaho-platform
#Inform comma separated list of projects to be packaged
ARG PROJECTS=pentaho-server-ce
RUN echo "Received ARG PROJECTS: $PROJECTS" && \
    export PROJECTS=$(echo $PROJECTS | sed -r "s/^\b/pentaho:/g; s/(,\b)/,pentaho:/g;") && \
    echo "Preparing packages for the sub-projects: $PROJECTS" && \
    mvn --projects $PROJECTS \
#    --resume-from $PROJECTS \
    --also-make --fail-fast \
    clean package -Dmaven.test.skip=true
#RUN mvn --also-make dependency:tree | grep maven-dependency-plugin | awk '{ print $(NF-1) }'
#Expose packages in external volume
VOLUME packages:/opt/pentaho-platform/assemblies

CMD ["/bin/sh"]