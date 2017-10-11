#!/bin/bash
 
HOSTNAME=`hostname`

cd /tmp/zookeeper
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
echo "verify is latest code"
echo "first zk is ------$ZK"
echo "$MYID"
rm -f /dat1/marker
touch /dat1/marker
#IPADDRESS=`ip -4 addr show scope global dev eth0 | grep inet | awk '{print \$ZK}' | cut -d / -f 1`

if [ "$Index" = "0" ];then
  echo "first node"
  ls /tmp/zookeeper/bin
  echo "server.$MYID=$HOSTNAME:2888:3888;2181" >> /tmp/zookeeper/conf/zoo.cfg.dynamic
  echo "==="
  /tmp/zookeeper/bin/zkServer-initialize.sh --force --myid="$MYID"
  echo "0--------------"
  echo "$MYID" >/tmp/zookeeper/myid
  echo "1-----------"
  ZOO_LOG_DIR=/var/log ZOO_LOG4J_PROP='INFO,CONSOLE,ROLLINGFILE' /tmp/zookeeper/bin/zkServer.sh start-foreground
  #/tmp/zookeeper/bin/zkServer.sh start
  echo "-=-=-=------------------"
  echo "`/tmp/zookeeper/bin/zkCli.sh get /zookeeper/config|grep ^server`" 
  echo "`/tmp/zookeeper/bin/zkCli.sh get /zookeeper/config|grep ^server`" >> /dat1/marker
else
  echo "adding to existed"
  cat /dat1/marker
  cat /dat1/marker >> /tmp/zookeeper/conf/zoo.cfg.dynamic
  #echo "`bin/zkCli.sh -server $ZK:2181 get /zookeeper/config|grep ^server`" 
  #echo "`bin/zkCli.sh -server $ZK:2181 get /zookeeper/config|grep ^server`" >> /tmp/zookeeper/conf/zoo.cfg.dynamic
  echo "server.$MYID=$HOSTNAME:2888:3888:observer;2181" >> /tmp/zookeeper/conf/zoo.cfg.dynamic
  cp /tmp/zookeeper/conf/zoo.cfg.dynamic /tmp/zookeeper/conf/zoo.cfg.dynamic.org
  /tmp/zookeeper/bin/zkServer-initialize.sh --force --myid=$MYID
  echo "$MYID" >/tmp/zookeeper/myid
  ZOO_LOG_DIR=/var/log ZOO_LOG4J_PROP='INFO,CONSOLE,ROLLINGFILE' /tmp/zookeeper/bin/zkServer.sh start
  /tmp/zookeeper/bin/zkCli.sh -server $ZK:2181 reconfig -add "server.$MYID=$IPADDRESS:2888:3888:participant;2181"
  /tmp/zookeeper/bin/zkServer.sh stop
  ZOO_LOG_DIR=/var/log ZOO_LOG4J_PROP='INFO,CONSOLE,ROLLINGFILE' /tmp/zookeeper/bin/zkServer.sh start-foreground
  
  
fi
