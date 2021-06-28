FROM openjdk:8u212-jre-alpine

ARG PENTAHO_VERSION=9.1
ARG PENTAHO_TAG=9.1.0.0-324
ENV PENTAHO_HOME=/opt/pentaho
ENV PATH=$PATH:${PENTAHO_HOME} \
    CLASSPATH=${PENTAHO_HOME}/lib-ext/*${CLASSPATH:+:$CLASSPATH} \
    COMPOSE_CONVERT_WINDOWS_PATHS=1 \
    TZ=America/Sao_Paulo \
    CATALINA_OPTS="-Djava.awt.headless=true -Xms4096m -Xmx6144m -XX:MaxPermSize=256m -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000"

    #Add external libs files to classpath

WORKDIR /opt

RUN wget -O pentaho-server-ce-${PENTAHO_TAG}.zip \
    "https://sourceforge.net/projects/pentaho/files/Pentaho ${PENTAHO_VERSION}/server/pentaho-server-ce-${PENTAHO_TAG}.zip"

RUN unzip pentaho-server-ce-${PENTAHO_TAG}.zip \
    && rm pentaho-server-ce-${PENTAHO_TAG}.zip \
    && ln -s pentaho-server /opt/pentaho

WORKDIR /opt/pentaho

COPY ./conf/ pentaho-solutions/

RUN adduser -h ${PENTAHO_HOME} -D -s /bin/sh pentaho  \
    && chown -R pentaho:pentaho ${PENTAHO_HOME} \
    #&& mkdir -p ${KETTLE_HOME} \
    && mkdir ./lib-ext \
    && mkdir -p /mnt/data \
    && chown -R pentaho:pentaho /mnt/data

VOLUME ./lib:/opt/pentaho/lib-ext
#Schedule/Quartz/hibernate
VOLUME $PENTAHO_HOME/data/hsqldb
#login, connectinons, JOB, TR
VOLUME $PENTAHO_HOME/pentaho-solutions/system/jackrabbit/repository
VOLUME ./logs:$PENTAHO_HOME/tomcat/logs
VOLUME /mnt/data

#Copy defaults lib files to image
COPY  ./lib ./tomcat/lib/
#Copy configuraiton files
COPY conf/ ./pentaho-solutions/

#COPY conf/pentaho /etc/init.d/

RUN sed -i -e 's/\(exec ".*"\) start/\1 run/' ./tomcat/bin/startup.sh  \
    #sed -i -e 's/$errCode/$?/' ./start-pentaho.sh \
    #&& chmod +x /etc/init.d/pentaho \
    #&& update-rc.d pentaho defaults
    && chmod +x ./start-pentaho.sh \
    && rm ./promptuser.sh

EXPOSE 8080

ENTRYPOINT ["start-pentaho.sh"]
CMD ["/bin/sh"]
#docker build --rm --build-arg PENTAHO_VERSION=8.2 --build-arg PENTAHO_TAG=8.2.0.0-342 -t bergerrc/pentaho:8.2 .