FROM goodrainapps/openjdk:8u131-jre-alpine
MAINTAINER Elisey Zanko <elisey.zanko@gmail.com>

# Install required packages
RUN apk update && apk upgrade && \
apk add --no-cache git 

# Ant
ENV ANT_FILENAME=apache-ant-1.9.7 \
    ANT_HOME=/opt/ant \
    PATH=${PATH}:/opt/ant/bin

ADD https://www.apache.org/dist/ant/binaries/${ANT_FILENAME}-bin.tar.bz2 /tmp/ant.tar.bz2

RUN tar -C /opt -xjf /tmp/ant.tar.bz2 && \
    ln -s /opt/${ANT_FILENAME} /opt/ant && \
rm -rf /tmp/* /var/cache/apk/* /opt/ant/manual/*

RUN apk add --no-cache \
    bash \
    su-exec

RUN mkdir /tmp/zookeeper
WORKDIR /tmp/zookeeper
RUN git clone https://github.com/apache/zookeeper.git .
RUN git checkout release-3.5.1-rc2
RUN ant jar
ENV ZOO_CONF_DIR=/tmp/zookeeper/conf \
    ZOO_DATA_DIR=/data \
    ZOO_DATA_LOG_DIR=/datalog \
    ZOO_PORT=2181 \
    ZOO_TICK_TIME=2000 \
    ZOO_INIT_LIMIT=5 \
    ZOO_SYNC_LIMIT=2

# Add a user and make dirs
RUN set -x \
    && adduser -D "$ZOO_USER" \
    && mkdir -p "$ZOO_DATA_LOG_DIR" "$ZOO_DATA_DIR" "$ZOO_CONF_DIR" \
    && chown "$ZOO_USER:$ZOO_USER" "$ZOO_DATA_LOG_DIR" "$ZOO_DATA_DIR" "$ZOO_CONF_DIR"


EXPOSE 2181 2888 3888
ENV PATH=$PATH:/tmp/zookeeper/bin

RUN cp /tmp/zookeeper/conf/zoo_sample.cfg /tmp/zookeeper/conf/zoo.cfg
RUN echo "standaloneEnabled=false" >> /tmp/zookeeper/conf/zoo.cfg
RUN echo "dynamicConfigFile=/tmp/zookeeper/conf/zoo.cfg.dynamic" >> /tmp/zookeeper/conf/zoo.cfg
COPY entrypoint.sh /tmp
RUN chmod 777 /tmp/entrypoint.sh
ENTRYPOINT ["/tmp/entrypoint.sh"]
