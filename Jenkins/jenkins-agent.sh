#!/bin/bash

sudo yum update -y

sudo yum -y install java-11-openjdk java-11-openjdk-devel

sudo yum -y install maven

# at this point we have java and maven
# To do:
# get the jar file
# run the jar file (need the secret value and the controller IP for this command)



echo $1 > /tmp/foo.txt