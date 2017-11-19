FROM goodrainapps/openjdk:8u131-jdk-alpine
MAINTAINER Bay1ts <bay1ts@163.com>

# Install required packages
RUN apk update && apk upgrade && \
apk add --no-cache git 


#####
# Ant
#####

# Preparation

ENV ANT_VERSION 1.9.9
ENV ANT_HOME /etc/ant-${ANT_VERSION}

# Installation

RUN cd /tmp \
    && wget http://www.us.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz \
    && mkdir ant-${ANT_VERSION} \
    && tar -zxvf apache-ant-${ANT_VERSION}-bin.tar.gz \
    && mv apache-ant-${ANT_VERSION} ${ANT_HOME} \
    && rm apache-ant-${ANT_VERSION}-bin.tar.gz \
    && rm -rf ant-${ANT_VERSION} \
    && rm -rf ${ANT_HOME}/manual \
    && unset ANT_VERSION
ENV PATH ${PATH}:${ANT_HOME}/bin

RUN apk add --no-cache \
    bash \
    su-exec

RUN mkdir /tmp/zookeeper
WORKDIR /tmp/zookeeper
RUN git clone https://github.com/apache/zookeeper.git .
RUN git checkout release-3.5.1-rc2
RUN ant jar
RUN echo "build zookeeper  success"
EXPOSE 2181 2888 3888
VOLUME ["/dat1"]
RUN cp /tmp/zookeeper/conf/zoo_sample.cfg /tmp/zookeeper/conf/zoo.cfg
RUN echo "standaloneEnabled=false" >> /tmp/zookeeper/conf/zoo.cfg
RUN echo "minSessionTimeout=4000000" >> /tmp/zookeeper/conf/zoo.cfg
RUN echo "maxSessionTimeout=10000000" >> /tmp/zookeeper/conf/zoo.cfg
RUN echo "dynamicConfigFile=/tmp/zookeeper/conf/zoo.cfg.dynamic" >> /tmp/zookeeper/conf/zoo.cfg
COPY entrypoint.sh /tmp/
COPY java_mem_common.sh /

RUN echo "coping entry"
RUN chmod 777 /tmp/entrypoint.sh
RUN chmod 777 /java_mem_common.sh
ENTRYPOINT ["/tmp/entrypoint.sh"]
