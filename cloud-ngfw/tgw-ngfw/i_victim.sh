#!/bin/bash

# Update hostname for better identification
sudo hostname victim

echo wait for internet
for i in $(seq 1 60); do
  ping -c 1 one.one.one.one && break
  sleep 5
done
echo done waiting for internet

# Updating yum repositories
sudo yum update -y

# Installing Docker
sudo amazon-linux-extras install docker
sudo yum install -y docker tcpdump

# Starting Docker
sudo service docker start
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user
sudo docker info

# Downloading and Running the Vulnerable App Server Demo App
sudo docker container run -itd --rm --name vul-app-1 -p 8080:8080 us.gcr.io/panw-gcp-team-testing/qwiklab/pcc-log4shell/l4s-demo-app:1.0

# Updating the /etc/hosts file to add a DNS entry for the attack server
sudo docker exec vul-app-1 /bin/sh -c 'echo "172.16.1.21    att-svr" >> /etc/hosts'
