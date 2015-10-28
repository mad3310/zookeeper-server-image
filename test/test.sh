NODE_NAME="docker-zookeeper-test-node-1"
IP="10.154.238.241"
IMAGE="10.160.140.32:5000/letv-zookeeper:0.0.2"


docker run -i -t --rm --privileged -h $NODE_NAME \
--env "NODE_COUNT=1" \
--env "ZKID=1" \
--env "IFACE=peth0" \
--env "IP=$IP" \
--env "HOSTNAME=$NODE_NAME" \
--env "NETMASK=255.255.0.0" \
--env "GATEWAY=10.154.0.1"  \
--env "N1_IP=$IP"  \
--env "N1_HOSTNAME=$NODE_NAME"  \
--name $NODE_NAME $IMAGE
