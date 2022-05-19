#!/bin/bash
# this code is based on https://kevin-denotariis.medium.com/download-install-and-setup-jenkins-completely-from-bash-unlock-create-admin-user-and-more-debd3320414a

url=http://localhost:8080
password=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

# url encode the credentials
username=$(python -c "import urllib;print urllib.quote(raw_input(), safe='')" <<< "jenkins-admin-2707") # only hard coded for testing
new_password=$(python -c "import urllib;print urllib.quote(raw_input(), safe='')" <<< "insecure-pass-65537") # only hard coded for testing
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

# MAKE THE REQUEST TO CREATE AN ADMIN USER
curl -X POST -u "admin:$password" $url/setupWizard/createAdminUser \
        -H "Connection: keep-alive" \
        -H "Accept: application/json, text/javascript" \
        -H "X-Requested-With: XMLHttpRequest" \
        -H "$crumb_data" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --cookie $cookie_jar \
        --data "username=$username&password1=$new_password&password2=$new_password&fullname=$fullname&email=$email&Jenkins-Crumb=$crumb&json=%7B%22username%22%3A%20%22$username%22%2C%20%22password1%22%3A%20%22$new_password%22%2C%20%22%24redact%22%3A%20%5B%22password1%22%2C%20%22password2%22%5D%2C%20%22password2%22%3A%20%22$new_password%22%2C%20%22fullname%22%3A%20%22$fullname%22%2C%20%22email%22%3A%20%22$email%22%2C%20%22Jenkins-Crumb%22%3A%20%22$crumb%22%7D&core%3Aapply=&Submit=Save&json=%7B%22username%22%3A%20%22$username%22%2C%20%22password1%22%3A%20%22$new_password%22%2C%20%22%24redact%22%3A%20%5B%22password1%22%2C%20%22password2%22%5D%2C%20%22password2%22%3A%20%22$new_password%22%2C%20%22fullname%22%3A%20%22$fullname%22%2C%20%22email%22%3A%20%22$email%22%2C%20%22Jenkins-Crumb%22%3A%20%22$crumb%22%7D"