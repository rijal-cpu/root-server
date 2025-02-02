#!/bin/bash

rm -rf /root/.bash_history .bash_logout .bash_profile
rm -rf /tmp/*
chmod -R 000 /var/log/
find /var/log/ -type f -exec truncate -s 0 {} \;
find /var/www/vhosts/ -type f -name .bash_history -exec rm -f {} \;
sudo yum clean all
sudo yum makecache
service nginx restart
/sbin/service sshd restart
/sbin/init 6
