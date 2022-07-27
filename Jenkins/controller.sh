#!/bin/bash

################################
# Software installation
################################

sudo yum update -y
sudo yum -y install java-11-openjdk java-11-openjdk-devel
sudo yum -y install git
sudo yum -y install libicu

# get/validate/install jenkins
sudo wget -P /etc/yum.repos.d "http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo"
sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key
sudo yum -y install jenkins
# get/validate/install azure cli
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/azure-cli.repo
sudo yum -y install azure-cli

sudo systemctl start jenkins
sudo systemctl enable jenkins

################################
# Configuration Step 1 - Unlock
################################

url=http://10.6.0.4:8080 # changed from 10.5.0.4. Need to find a good way to parameterize this.
password=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

# create variables for Jenkins credentials
# they are passed in as secure parameters
# url encode with python
username=$(python -c "import urllib;print urllib.quote(raw_input(), safe='')" <<< $1) # First argument is username
new_password=$(python -c "import urllib;print urllib.quote(raw_input(), safe='')" <<< $2) # Second argument is password
fullname=$(python -c "import urllib;print urllib.quote(raw_input(), safe='')" <<< "Jenkins Administrator")
email=$(python -c "import urllib;print urllib.quote(raw_input(), safe='')" <<< "hello@xyz.com")

# Use 'initialAdminPassword' to get crumb data for authentication
cookie_jar="$(mktemp)"
crumb_data=$(curl -u "admin:$password" --cookie-jar "$cookie_jar" $url/crumbIssuer/api/xml?xpath=concat\(//crumbRequestField,%22:%22,//crumb\))
arr_crumb=(${crumb_data//:/ })
crumb=$(echo ${arr_crumb[1]})

# POST request to create a Jenkins admin user
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
crumb_data=$(curl -u "$username:$new_password" --cookie-jar "$cookie_jar" $url/crumbIssuer/api/xml?xpath=concat\(//crumbRequestField,%22:%22,//crumb\))
arr_crumb=(${crumb_data//:/ })
crumb=$(echo ${arr_crumb[1]})

# POST request to install recommended plugins
curl -X POST -u "$username:$new_password" $url/pluginManager/installPlugins \
  -H 'Connection: keep-alive' \
  -H 'Accept: application/json, text/javascript, */*; q=0.01' \
  -H 'X-Requested-With: XMLHttpRequest' \
  -H "$crumb_data" \
  -H 'Content-Type: application/json' \
  -H 'Accept-Language: en,en-US;q=0.9,it;q=0.8' \
  --cookie $cookie_jar \
  --data "{'dynamicLoad':true,'plugins':['cloudbees-folder','antisamy-markup-formatter','build-timeout','credentials-binding','timestamper','ws-cleanup','ant','gradle','workflow-aggregator','github-branch-source','pipeline-github-lib','pipeline-stage-view','git','ssh-slaves','matrix-auth','pam-auth','ldap','email-ext','mailer','azure-cli'],'Jenkins-Crumb':'$crumb'}"


################################
# Configuration Step 3 - URL
################################

url_urlEncoded=$(python -c "import urllib;print urllib.quote(raw_input(), safe='')" <<< $url)

cookie_jar="$(mktemp)"
crumb_data=$(curl -u "$username:$new_password" --cookie-jar "$cookie_jar" $url/crumbIssuer/api/xml?xpath=concat\(//crumbRequestField,%22:%22,//crumb\))
arr_crumb=(${crumb_data//:/ })
crumb=$(echo ${arr_crumb[1]})

# POST request to set the Jenkins URL
curl -X POST -u "$username:$new_password" $url/setupWizard/configureInstance \
  -H 'Connection: keep-alive' \
  -H 'Accept: application/json, text/javascript, */*; q=0.01' \
  -H 'X-Requested-With: XMLHttpRequest' \
  -H "$crumb_data" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'Accept-Language: en,en-US;q=0.9,it;q=0.8' \
  --cookie $cookie_jar \
  --data "rootUrl=$url_urlEncoded%2F&Jenkins-Crumb=$crumb&json=%7B%22rootUrl%22%3A%20%22$url_urlEncoded%2F%22%2C%20%22Jenkins-Crumb%22%3A%20%22$crumb%22%7D&core%3Aapply=&Submit=Save&json=%7B%22rootUrl%22%3A%20%22$url_urlEncoded%2F%22%2C%20%22Jenkins-Crumb%22%3A%20%22$crumb%22%7D"