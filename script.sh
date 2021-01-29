#!/bin/bash
# sleep until instance is ready
until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done
# install nginx
yum -y update
yum -y install nginx
yum -y install jq git curl wget 
cp /tmp/hellworld.html /var/nginx/
# make sure nginx is started
service nginx start
