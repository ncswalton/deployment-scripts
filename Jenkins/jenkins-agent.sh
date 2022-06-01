#!/bin/bash

sudo yum update -y

sudo yum -y install java-11-openjdk java-11-openjdk-devel

sudo yum -y install maven

mkdir -p build/software/maven/

wget https://www-eu.apache.org/dist/maven/maven-3/3.6.2/binaries/apache-maven-3.6.2-bin.tar.gz --directory /home/centos/build/software/maven/

tar -xvf /home/centos/build/software/maven/apache-maven-3.6.2-bin.tar.gz --directory /home/centos/build/software/

# at this point we have java and maven
# To do:
# get the jar file
# run the jar file (need the secret value and the controller IP for this command)

cat $1 > /tmp/foo.txt