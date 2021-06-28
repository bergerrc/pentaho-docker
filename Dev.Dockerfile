FROM openjdk:8u212-jre-alpine
ENV PENTAHO_HOME=/opt/pentaho
ENV PENTAHO_TAG=${PENTAHO_TAG:-9.2.0.0-SNAPSHOT}
ENV PATH=$PATH:${PENTAHO_HOME} \
    CLASSPATH=${PENTAHO_HOME}/lib-ext/*${CLASSPATH:+:$CLASSPATH} \
    COMPOSE_CONVERT_WINDOWS_PATHS=1 \
    TZ=America/Sao_Paulo \
    CATALINA_OPTS="-Djava.awt.headless=true -Xms4096m -Xmx6144m -XX:MaxPermSize=256m -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000"

    #Add external libs files to classpath

WORKDIR /opt
RUN wget -O pentaho-server-ce.zip \
    "https://repo.orl.eng.hitachivantara.com/artifactory/pntpub-mvn-snapshot-orl-cache/pentaho/pentaho-server-ce/${PENTAHO_TAG}"
RUN unzip pentaho-server-ce.zip \
    && rm pentaho-server-ce.zip \
    && ln -s pentaho-server /opt/pentaho

RUN ln -s pentaho-server /opt/pentaho

WORKDIR /opt/pentaho

#ENV KETTLE_HOME=${KETTLE_HOME:-${PENTAHO_HOME}/pdi}

RUN adduser -h ${PENTAHO_HOME} -D -s /bin/sh pentaho  \
    && chown -R pentaho:pentaho ${PENTAHO_HOME} \
    #&& mkdir -p ${KETTLE_HOME} \
    && mkdir ./lib-ext

VOLUME ./lib:/opt/pentaho/lib-ext
#Schedule/Quartz/hibernate
VOLUME ./data/internal:$PENTAHO_HOME/data/hsqldb
#login, connectinons, JOB, TR
VOLUME ./data/repository:$PENTAHO_HOME/pentaho-solutions/system/jackrabbit/repository
VOLUME ./logs:$PENTAHO_HOME/pentaho-server/tomcat/logs

#VOLUME kettle_home:${KETTLE_HOME}

#Copy defaults lib files to image
COPY jdbc/*.jar ./tomcat/lib
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