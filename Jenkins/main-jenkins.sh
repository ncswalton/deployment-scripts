#!/bin/bash

################################
# Software installation
################################

# package update
sudo yum update -y

# install java
sudo yum -y install java-11-openjdk java-11-openjdk-devel

# get jenkins
sudo wget -P /etc/yum.repos.d "http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo"

# validate repo 
sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key

# install jenkins
sudo yum -y install jenkins

# start/enable jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

################################
# Configuration Step 1 - Unlock
################################

url=http://localhost:8080
password=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

# create variables for Jenkins credentials
# they are passed in as command line arguments
# url encode with python
username=$(python -c "import urllib;print urllib.quote(raw_input(), safe='')" <<< $1) # First argument is username
new_password=$(python -c "import urllib;print urllib.quote(raw_input(), safe='')" <<< $2) # Second argument is password
fullname=$(python -c "import urllib;print urllib.quote(raw_input(), safe='')" <<< "Jenkins Administrator")
email=$(python -c "import urllib;print urllib.quote(raw_input(), safe='')" <<< "hello@xyz.com")

echo "username: ${username}"
echo "new_password: ${new_password}"
echo "fullname: ${fullname}"
echo "email: ${email}"

# here we get the crumb data and extract the crumb itself into its own variable
# test this
cookie_jar="$(mktemp)"
crumb_data=$(curl -u "admin:$password" --cookie-jar "$cookie_jar" $url/crumbIssuer/api/xml?xpath=concat\(//crumbRequestField,%22:%22,//crumb\))
arr_crumb=(${crumb_data//:/ })
crumb=$(echo ${arr_crumb[1]})

# use curl to make a POST request that creates an admin user with the credentials
# path is <jenkins ip>:8080/setupWizard/createAdminUser
# changed "--data-raw" to "--data"
curl -X POST -u "admin:$password" $url/setupWizard/createAdminUser \
        -H "Connection: keep-alive" \
        -H "Accept: application/json, text/javascript" \
        -H "X-Requested-With: XMLHttpRequest" \
        -H "$crumb_data" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --cookie $cookie_jar \
        --data "username=$username&password1=$new_password&password2=$new_password&fullname=$fullname&email=$email&Jenkins-Crumb=$crumb&json=%7B%22username%22%3A%20%22$username%22%2C%20%22password1%22%3A%20%22$new_password%22%2C%20%22%24redact%22%3A%20%5B%22password1%22%2C%20%22password2%22%5D%2C%20%22password2%22%3A%20%22$new_password%22%2C%20%22fullname%22%3A%20%22$fullname%22%2C%20%22email%22%3A%20%22$email%22%2C%20%22Jenkins-Crumb%22%3A%20%22$crumb%22%7D&core%3Aapply=&Submit=Save&json=%7B%22username%22%3A%20%22$username%22%2C%20%22password1%22%3A%20%22$new_password%22%2C%20%22%24redact%22%3A%20%5B%22password1%22%2C%20%22password2%22%5D%2C%20%22password2%22%3A%20%22$new_password%22%2C%20%22fullname%22%3A%20%22$fullname%22%2C%20%22email%22%3A%20%22$email%22%2C%20%22Jenkins-Crumb%22%3A%20%22$crumb%22%7D"


################################
# Configuration Step 2 - Plugins
################################

cookie_jar="$(mktemp)"
crumb_data=$(curl -u "$user:$password" --cookie-jar "$cookie_jar" $url/crumbIssuer/api/xml?xpath=concat\(//crumbRequestField,%22:%22,//crumb\))
arr_crumb=(${crumb_data//:/ })
crumb=$(echo ${arr_crumb[1]})

# MAKE THE REQUEST TO DOWNLOAD AND INSTALL REQUIRED MODULES
curl -X POST -u "$user:$password" $url/pluginManager/installPlugins \
  -H 'Connection: keep-alive' \
  -H 'Accept: application/json, text/javascript, */*; q=0.01' \
  -H 'X-Requested-With: XMLHttpRequest' \
  -H "$crumb_data" \
  -H 'Content-Type: application/json' \
  -H 'Accept-Language: en,en-US;q=0.9,it;q=0.8' \
  --cookie $cookie_jar \
  --data "{'dynamicLoad':true,'plugins':['cloudbees-folder','antisamy-markup-formatter','build-timeout','credentials-binding','timestamper','ws-cleanup','ant','gradle','workflow-aggregator','github-branch-source','pipeline-github-lib','pipeline-stage-view','git','ssh-slaves','matrix-auth','pam-auth','ldap','email-ext','mailer'],'Jenkins-Crumb':'$crumb'}"


################################
# Configuration Step 3 - URL
################################

url_urlEncoded=$(python -c "import urllib;print urllib.quote(raw_input(), safe='')" <<< "$url")

cookie_jar="$(mktemp)"
crumb_data=$(curl -u "$user:$password" --cookie-jar "$cookie_jar" $url/crumbIssuer/api/xml?xpath=concat\(//crumbRequestField,%22:%22,//crumb\))
arr_crumb=(${crumb_data//:/ })
crumb=$(echo ${arr_crumb[1]})

curl -X POST -u "$user:$password" $url/setupWizard/configureInstance \
  -H 'Connection: keep-alive' \
  -H 'Accept: application/json, text/javascript, */*; q=0.01' \
  -H 'X-Requested-With: XMLHttpRequest' \
  -H "$crumb_data" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'Accept-Language: en,en-US;q=0.9,it;q=0.8' \
  --cookie $cookie_jar \
  --data-raw "rootUrl=$url_urlEncoded%2F&Jenkins-Crumb=$crumb&json=%7B%22rootUrl%22%3A%20%22$url_urlEncoded%2F%22%2C%20%22Jenkins-Crumb%22%3A%20%22$crumb%22%7D&core%3Aapply=&Submit=Save&json=%7B%22rootUrl%22%3A%20%22$url_urlEncoded%2F%22%2C%20%22Jenkins-Crumb%22%3A%20%22$crumb%22%7D"