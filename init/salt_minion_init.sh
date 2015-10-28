sed -i "42s/.*/id: $(hostname)/" /etc/salt/minion
service salt-minion start

