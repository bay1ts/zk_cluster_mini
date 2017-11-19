#!/bin/bash

# Simply determine if any instances exist other than this one. If there are any
# others, then assume that a cluster already exists and create a marker to
# signal that we shouldn't create a new one.
mkdir -p /zk/zk-data
nodes=""
while read -r line
do
    if [ -z $nodes ];then
      nodes="$line"
    else  
      nodes="$nodes,$line"
    fi  
done
if [ $nodes ];then
   echo $nodes > /zk/zk-data/nodes
fi
if echo $nodes | grep -v "$(hostname)"; then
   touch /zk/zk-data/cluster_exists_marker
fi
