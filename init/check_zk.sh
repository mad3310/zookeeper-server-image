#!/bin/bash
ZOOKEEPER_STATUS=`ps -ef|grep Dzookeeper | grep -v grep | wc -l`
if [ $ZOOKEEPER_STATUS -eq 0 ]
then
/usr/local/zookeeper/bin/zkServer.sh start
fi
