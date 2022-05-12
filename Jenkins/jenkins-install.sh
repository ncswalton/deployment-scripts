#!/bin/bash

# package update
sudo yum update -y

# install java
sudo yum -y install java-11-openjdk java-11-openjdk-devel

# get jenkins
# sudo wget –O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo
sudo wget -P /etc/yum.repos.d "http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo"
# jenkins security key [?]
# sudo rpm ––import https://pkg.jenkins.io/redhat/jenkins.io.key
sudo rpm ––install https://pkg.jenkins.io/redhat/jenkins.io.key

# install jenkins
sudo yum -y install jenkins

# start jenkins
sudo systemctl start jenkins

# enable jenkins
sudo systemctl enable jenkins
