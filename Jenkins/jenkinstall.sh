#!/bin/bash

yum update -y

yum -y install java-11-openjdk java-11-openjdk-devel

sudo wget –O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo

sudo rpm ––import https://pkg.jenkins.io/redhat/jenkins.io.key

sudo yum install jenkins

sudo systemctl start jenkins
sudo systemctl enable jenkins