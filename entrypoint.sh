#!/bin/bash
 
HOSTNAME=`hostname`

cd /tmp/zkapp
OLD_IFS="$IFS" 
IFS="-" 
arr=($HOSTNAME) 
IFS="$OLD_IFS"
HOSTN=${arr[@]:0:1}
Index=${arr[@]:1:1}
echo "index is $Index"
echo "hostname is $HOSTN"
MYID=`expr $Index + 1`
ZK=${HOSTN}"-0"
#IPADDRESS=`ip -4 addr show scope global dev eth0 | grep inet | awk '{print \$ZK}' | cut -d / -f 1`

sed -i '177i if [ -e "/java_mem_common.sh" ];then' /tmp/zkapp/bin/zkServer.sh
sed -i '178i . "/java_mem_common.sh"' /tmp/zkapp/bin/zkServer.sh
sed -i "179i fi" /tmp/zkapp/bin/zkServer.sh

/peer-finder -on-start=/on-start.sh -service=$(echo $SERVICE_NAME)
echo "begin check is cluster"
if [ ! "$(hostname)" == "$(echo $SERVICE_NAME)-0" ] || \
    [ -e "/zk/zk-data/cluster_exists_marker" ]
then
  node=cat /zk/zk-data/first_node
  echo "adding to existed node $node"
  echo "`bin/zkCli.sh -server $node:2181 get /zookeeper/config|grep ^server`" 
  echo "server.1=$ZK.$HOSTN:2888:3888:participant;0.0.0.0:2181" >> /tmp/zkapp/conf/zoo.cfg.dynamic
  echo "server.$MYID=$HOSTNAME.$HOSTN:2888:3888:observer;2181" >> /tmp/zkapp/conf/zoo.cfg.dynamic
  cp /tmp/zkapp/conf/zoo.cfg.dynamic /tmp/zkapp/conf/zoo.cfg.dynamic.org
  /tmp/zkapp/bin/zkServer-initialize.sh --force --myid=$MYID
  echo "$MYID" >/tmp/zkapp/myid
  echo "$MYID" >/tmp/zkapp/zookeeper_server.pid
  ZOO_LOG_DIR=/var/log ZOO_LOG4J_PROP='INFO,CONSOLE,ROLLINGFILE' /tmp/zkapp/bin/zkServer.sh start
  /tmp/zkapp/bin/zkCli.sh -server $ZK.$HOSTN:2181 reconfig -add "server.$MYID=$HOSTNAME.$HOSTN:2888:3888:participant;2181"
  /tmp/zkapp/bin/zkServer.sh stop
  ZOO_LOG_DIR=/var/log ZOO_LOG4J_PROP='INFO,CONSOLE,ROLLINGFILE' exec /tmp/zkapp/bin/zkServer.sh start-foreground
else
  echo "first node"
  echo "server.$MYID=$HOSTNAME.$HOSTN:2888:3888;2181"
  echo "server.$MYID=$HOSTNAME.$HOSTN:2888:3888;2181" >> /tmp/zkapp/conf/zoo.cfg.dynamic
  /tmp/zkapp/bin/zkServer-initialize.sh --force --myid="$MYID"
  echo "$MYID" >/tmp/zkapp/myid
  echo "$MYID" >/tmp/zkapp/zookeeper_server.pid
  ZOO_LOG_DIR=/var/log ZOO_LOG4J_PROP='INFO,CONSOLE,ROLLINGFILE' exec /tmp/zkapp/bin/zkServer.sh start-foreground
  
fi
