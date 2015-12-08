FROM 10.160.140.32:5000/letv-centos6
MAINTAINER bingzheng.zhou <zhoubingzheng@letv.com>

RUN rpm -ivh http://pkg-repo.oss.letv.com/pkgs/centos6/letv-release.noarch.rpm
RUN yum install cronie -y
RUN yum install vim -y
RUN yum update bash -y
RUN yum update tar -y
RUN yum install java-1.7.0-openjdk-devel -y

EXPOSE 4567 4568 4569 2181 2888 3888
USER root

RUN mkdir -p /usr/local/init/
RUN mkdir -p /usr/local/zookeeper/

ADD ./init/zookeeper.tar.gz /usr/local/
ADD ./init/zookeeper_docker_init.sh /usr/local/zookeeper/zookeeper_docker_init.sh

ADD ./init/salt-minion-2014.7.0-3.el6.noarch.rpm /tmp/salt-minion-2014.7.0-3.el6.noarch.rpm
ADD ./init/salt-2014.7.0-3.el6.noarch.rpm /tmp/salt-2014.7.0-3.el6.noarch.rpm
RUN yum -y localinstall /tmp/salt-2014.7.0-3.el6.noarch.rpm /tmp/salt-minion-2014.7.0-3.el6.noarch.rpm
RUN rm -rf /etc/salt/*
ADD ./init/minion /etc/salt/minion
ADD ./init/salt_minion_init.sh /usr/local/init/salt_minion_init.sh

RUN chmod 775 /usr/local/zookeeper/zookeeper_docker_init.sh
RUN chmod 755 /usr/local/init/salt_minion_init.sh

#zookeeper check  crontab
ADD ./init/check_zk.sh /usr/local/init/check_zk.sh 
RUN chmod 755 /usr/local/init/check_zk.sh

ENTRYPOINT /usr/local/zookeeper/zookeeper_docker_init.sh && /usr/local/zookeeper/bin/zkServer.sh start && /usr/local/init/salt_minion_init.sh && /bin/bash
