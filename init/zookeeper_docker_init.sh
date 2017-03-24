#! /bin/bash

function checkvar(){
  if [ ! $2 ]; then
    echo ERROR: need  $1
    exit 1
  fi
}

function loop_check(){
    for (( i = 1; i <= $1; i++ ))
    do
        param=`printf $2 $i`
        checkvar param ${!param}
    done
}

NS_IP="N%s_IP"
NS_HOSTNAME="N%s_HOSTNAME"

#check env
checkvar NODE_COUNT $NODE_COUNT
checkvar ZKID $ZKID
checkvar IP $IP
checkvar NETMASK $NETMASK
checkvar GATEWAY $GATEWAY

loop_check $NODE_COUNT $NS_IP
loop_check $NODE_COUNT $NS_HOSTNAME

#hosts
umount /etc/hosts
echo "127.0.0.1 localhost" > /etc/hosts
for (( i = 1; i <= $NODE_COUNT; i++ ))
do
    ip=`printf $NS_IP $i`
    name=`printf $NS_HOSTNAME $i`
    echo ${!ip} ${!name} >> /etc/hosts
done
echo 'set host successfully'

#network
IFACE=${IFACE:-peth1}
cat > /etc/sysconfig/network-scripts/ifcfg-$IFACE << EOF
DEVICE=$IFACE
ONBOOT=yes
BOOTPROTO=static
IPADDR=$IP
NETMASK=$NETMASK
GATEWAY=$GATEWAY
EOF
ifconfig $IFACE $IP/24
echo 'set network successfully'

#route
gateway=`echo $IP | cut -d. -f1,2`.91.1
route del -net 0.0.0.0 netmask 0.0.0.0 dev eth0
route add default gw $gateway

#zoo.cfg
mkdir -p /etc/zookeeper/conf/
cat > /etc/zookeeper/conf/zoo.cfg << EOF
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/var/lib/zookeeper
clientPort=2181
maxClientCnxns=0
EOF

for (( i = 1; i <= $NODE_COUNT; i++ ))
do
    ip=`printf $NS_IP $i`
    echo "server."${i}=""${!ip}":2888:3888">> /etc/zookeeper/conf/zoo.cfg
done
echo $ZKID > /etc/zookeeper/conf/myid
mkdir /var/lib/zookeeper
ln -s /etc/zookeeper/conf/myid /var/lib/zookeeper/myid
echo 'set zoo.cf and myid successuflly'

#crond init
is_wr_cron1=`grep "zookeeper" /etc/crontab |wc -l`
if [ $is_wr_cron1 -eq 0 ]
then
echo "1 */6 * * * root java -cp /usr/local/zookeeper/zookeeper-3.4.6.jar:/usr/local/zookeeper/lib/log4j-1.2.16.jar:/usr/local/zookeeper/lib/slf4j-api-1.6.1.jar:/usr/local/zookeeper/lib/slf4j-log4j12-1.6.1.jar:conf org.apache.zookeeper.server.PurgeTxnLog /var/lib/zookeeper/ -n 3" >> /etc/crontab
fi

is_wr_cron2=`grep "check_zk" /etc/crontab |wc -l`
if [ $is_wr_cron2 -eq 0 ]
then
echo "* * * * * root /usr/local/init/check_zk.sh > /tmp/check_zk.log 2>&1 &">> /etc/crontab
fi

service crond restart

$@
