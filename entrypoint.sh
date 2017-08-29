#!/bin/bash
 
HOSTNAME=`hostname`

cd "$ZOO_CONF_DIR"
OLD_IFS="$IFS" 
IFS="-" 
arr=($HOSTNAME) 
IFS="$OLD_IFS"
HOSTN=${arr[@]:0:1}
Index=${arr[@]:1:1}

 
((MYID=$Index+1)) 
ZK="$HOSTN"+0
#IPADDRESS=`ip -4 addr show scope global dev eth0 | grep inet | awk '{print \$ZK}' | cut -d / -f 1`

if [ "$Index"=="0" ]
then
  echo "server.$MYID=$HOSTNAME:2888:3888;2181" >> "$ZOO_CONF_DIR"/zoo.cfg.dynamic
  zkServer-initialize.sh --force --myid=$MYID
  zkServer.sh start-foreground
  
else
  echo "`zkCli.sh -server $ZK:2181 get /zookeeper/config|grep ^server`" >> "$ZOO_CONF_DIR"/zoo.cfg.dynamic
  echo "server.$MYID=$HOSTNAME:2888:3888:observer;2181" >> "$ZOO_CONF_DIR"/zoo.cfg.dynamic
  cp "$ZOO_CONF_DIR"/zoo.cfg.dynamic "$ZOO_CONF_DIR"/zoo.cfg.dynamic.org
  zkServer-initialize.sh --force --myid=$MYID
  zkServer.sh start
  zkCli.sh -server $ZK:2181 reconfig -add "server.$MYID=$HOSTNAME:2888:3888:participant;2181"
  zkServer.sh stop
  zkServer.sh start-foreground
fi
