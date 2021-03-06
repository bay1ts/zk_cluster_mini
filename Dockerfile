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

RUN mkdir /tmp/zkapp
WORKDIR /tmp/zkapp
RUN git clone https://github.com/apache/zookeeper.git .
RUN git checkout release-3.5.1-rc2
RUN ant jar
RUN echo "build zookeeper  success"
EXPOSE 2181 2888 3888
VOLUME ["/dat1"]
#RUN mkdir /tmp/zkdata
#RUN sed -i "s#/tmp/zookeeper#/tmp/zkdata#g"  /tmp/zookeeper/conf/zoo_sample.cfg
RUN cp /tmp/zkapp/conf/zoo_sample.cfg /tmp/zkapp/conf/zoo.cfg
RUN echo "standaloneEnabled=false" >> /tmp/zkapp/conf/zoo.cfg
RUN echo "minSessionTimeout=4000000" >> /tmp/zkapp/conf/zoo.cfg
RUN echo "maxSessionTimeout=10000000" >> /tmp/zkapp/conf/zoo.cfg
RUN echo "dynamicConfigFile=/tmp/zkapp/conf/zoo.cfg.dynamic" >> /tmp/zkapp/conf/zoo.cfg
ADD peer-finder /peer-finder
COPY entrypoint.sh /tmp/
COPY java_mem_common.sh /
COPY on-start.sh /
RUN echo "coping entry"
RUN chmod 755 /tmp/entrypoint.sh
RUN chmod 755 /java_mem_common.sh
RUN chmod 755 /on-start.sh
RUN chmod 755 /peer-finder
ENTRYPOINT ["/tmp/entrypoint.sh"]
