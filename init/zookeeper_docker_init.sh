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
IFACE=${IFACE:-pbond0}
cat > /etc/sysconfig/network-scripts/ifcfg-$IFACE << EOF
DEVICE=$IFACE
ONBOOT=yes
BOOTPROTO=static
IPADDR=$IP
NETMASK=$NETMASK
GATEWAY=$GATEWAY
EOF
ifconfig $IFACE $IP/16
echo 'set network successfully'

#route
gateway=`echo $IP | cut -d. -f1,2`.0.1
route add default gw $gateway
route del -net 0.0.0.0 netmask 0.0.0.0 dev eth0

#zoo.cfg
mkdir -p /etc/zookeeper/conf/
cat > /etc/zookeeper/conf/zoo.cfg << EOF
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/var/lib/zookeeper
clientPort=2181
maxClientCnxns=100
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
echo "1 */6 * * * root java -cp /usr/local/zookeeper/zookeeper-3.4.6.jar:/usr/local/zookeeper/lib/log4j-1.2.16.jar:/usr/local/zookeeper/lib/slf4j-api-1.6.1.jar:/usr/local/zookeeper/lib/slf4j-log4j12-1.6.1.jar:conf org.apache.zookeeper.server.PurgeTxnLog /var/lib/zookeeper/ -n 3" >> /etc/crontab

#zabbix init
cd /usr/local
chmod 775 zabbix_install.sh
./zabbix_install.sh
cd /usr/local/zabbix/conf
touch host.temp
echo "${IP},115.182.93.64,218.206.201.236,211.162.59.93,114.80.187.245,114.80.187.246,121.14.196.239,10.0.51.13" > host.temp
service crond restart
cd /usr/local/zabbix
./install.sh
./check_zabbix.sh

$@
