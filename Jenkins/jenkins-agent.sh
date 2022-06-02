#!/bin/bash

sudo yum update -y

sudo yum -y install java-11-openjdk java-11-openjdk-devel

sudo yum -y install maven

sudo yum -y install sshpass

# at this point we have java and maven
# To do:
# get the jar file
# run the jar file (need the secret value and the controller IP for this command)
# https://github.com/chorrell/install-jenkins-agent/blob/main/install-jenkins-agent.sh

echo $2 > /home/testUser/creds.txt

curl -o /home/testUser/agent.jar -Ssl http://$1:8080/jnlpJars/agent.jar

sshpass -f "/home/testUser/creds.txt" scp -r testUser@$1:/home/testUser/secret.txt /home/testUser/secret.txt
