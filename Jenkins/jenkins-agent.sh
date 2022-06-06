#!/bin/bash
# args[0] = controller ip, args[1] = jenkins pw, args[2] = username, args[3] = nodeName
# NOTE: script assumes a single shared username for Jenkins and the VMs.

# Package update, install Java & Maven
sudo yum update -y
sudo yum -y install java-11-openjdk java-11-openjdk-devel
sudo yum -y install maven

# Create directory on Agent VM for Jenkins
mkdir /opt/jenkins
# URL of Controller 
url="http://$1:8080"
password=$2 # maybe avoid storing in variable?
username=$3
# not using this right now
node_name=$4

# download agent.jar from the controller
curl -o /home/$3/agent.jar -Ssl "$url/jnlpJars/agent.jar"

# get cookie & crumb for auth
cookie_jar="$(mktemp)"
crumb_data=$(curl -u "$username:$password" --cookie-jar "$cookie_jar" $url/crumbIssuer/api/xml?xpath=concat\(//crumbRequestField,%22:%22,//crumb\))
arr_crumb=(${crumb_data//:/ })
crumb=$(echo ${arr_crumb[1]})

# this request creates the new node
# TODO: parameter for Node name, description, etc (currently hard coded in --data payload)
curl -X POST -u "$username:$password" $url/computer/doCreateItem \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
  -H 'Connection: keep-alive' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H "$crumb_data" \
  --cookie $cookie_jar \
  --data "name=CentOSDemoAgent&_.nodeDescription=CentOSDemoAgent&_.numExecutors=1&_.remoteFS=&_.labelString=&mode=NORMAL&stapler-class=hudson.slaves.JNLPLauncher&%24class=hudson.slaves.JNLPLauncher&_.workDirPath=&_.internalDir=remoting&_.webSocket=on&_.tunnel=&_.vmargs=&stapler-class=hudson.slaves.CommandLauncher&%24class=hudson.slaves.CommandLauncher&oldCommand=&_.command=&stapler-class=hudson.plugins.sshslaves.SSHLauncher&%24class=hudson.plugins.sshslaves.SSHLauncher&_.host=&includeUser=false&_.credentialsId=&stapler-class=hudson.plugins.sshslaves.verifiers.KnownHostsFileKeyVerificationStrategy&%24class=hudson.plugins.sshslaves.verifiers.KnownHostsFileKeyVerificationStrategy&stapler-class=hudson.plugins.sshslaves.verifiers.ManuallyProvidedKeyVerificationStrategy&%24class=hudson.plugins.sshslaves.verifiers.ManuallyProvidedKeyVerificationStrategy&stapler-class=hudson.plugins.sshslaves.verifiers.ManuallyTrustedKeyVerificationStrategy&%24class=hudson.plugins.sshslaves.verifiers.ManuallyTrustedKeyVerificationStrategy&stapler-class=hudson.plugins.sshslaves.verifiers.NonVerifyingKeyVerificationStrategy&%24class=hudson.plugins.sshslaves.verifiers.NonVerifyingKeyVerificationStrategy&_.port=22&_.javaPath=&_.jvmOptions=&_.prefixStartSlaveCmd=&_.suffixStartSlaveCmd=&launchTimeoutSeconds=&maxNumRetries=&retryWaitTime=&tcpNoDelay=on&workDir=&stapler-class=hudson.slaves.RetentionStrategy%24Always&%24class=hudson.slaves.RetentionStrategy%24Always&stapler-class=hudson.slaves.SimpleScheduledRetentionStrategy&%24class=hudson.slaves.SimpleScheduledRetentionStrategy&retentionStrategy.startTimeSpec=&retentionStrategy.upTimeMins=&retentionStrategy.keepUpWhenActive=on&stapler-class=hudson.slaves.RetentionStrategy%24Demand&%24class=hudson.slaves.RetentionStrategy%24Demand&retentionStrategy.inDemandDelay=&retentionStrategy.idleDelay=&stapler-class-bag=true&type=hudson.slaves.DumbSlave&Jenkins-Crumb=e91169d74e6a990c5d4d2ce78bd94236e5d5f15649115554d89ccc6899eb0f90&json=%7B%22name%22%3A+%22CentOS-Demo-Agent1%22%2C+%22nodeDescription%22%3A+%22CentOS-Demo-Agent1%22%2C+%22numExecutors%22%3A+%221%22%2C+%22remoteFS%22%3A+%22%22%2C+%22labelString%22%3A+%22%22%2C+%22mode%22%3A+%22NORMAL%22%2C+%22%22%3A+%5B%22hudson.slaves.JNLPLauncher%22%2C+%22hudson.slaves.RetentionStrategy%24Always%22%5D%2C+%22launcher%22%3A+%7B%22stapler-class%22%3A+%22hudson.slaves.JNLPLauncher%22%2C+%22%24class%22%3A+%22hudson.slaves.JNLPLauncher%22%2C+%22workDirSettings%22%3A+%7B%22disabled%22%3A+false%2C+%22workDirPath%22%3A+%22%22%2C+%22internalDir%22%3A+%22remoting%22%2C+%22failIfWorkDirIsMissing%22%3A+false%7D%2C+%22webSocket%22%3A+true%2C+%22tunnel%22%3A+%22%22%2C+%22vmargs%22%3A+%22%22%2C+%22oldCommand%22%3A+%22%22%7D%2C+%22retentionStrategy%22%3A+%7B%22stapler-class%22%3A+%22hudson.slaves.RetentionStrategy%24Always%22%2C+%22%24class%22%3A+%22hudson.slaves.RetentionStrategy%24Always%22%7D%2C+%22nodeProperties%22%3A+%7B%22stapler-class-bag%22%3A+%22true%22%7D%2C+%22type%22%3A+%22hudson.slaves.DumbSlave%22%2C+%22Jenkins-Crumb%22%3A+%22$crumb%22%7D&Submit=Save" \

# Cookie & crumb for auth
cookie_jar="$(mktemp)"
crumb_data=$(curl -u "$username:$password" --cookie-jar "$cookie_jar" $url/crumbIssuer/api/xml?xpath=concat\(//crumbRequestField,%22:%22,//crumb\))
arr_crumb=(${crumb_data//:/ })
crumb=$(echo ${arr_crumb[1]})

# Retrieve the secret string
# Use knowledge of string structure to do pattern matching
command=$(curl -u $username:$password $url/computer/CentOSDemoAgent/ \
  -H "Accept: application/json, text/javascript" \
  -H 'Connection: keep-alive' \
  -H "$crumb_data" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --cookie $cookie_jar 2>&1 |  grep -o 'jnlpUrl.*workDir' | head -1)

# jar command suffix
suffix=" /opt/jenkins"
# jar command prefix
prefix="nohup java -jar /home/$3/agent.jar -"
# Build command with suffix & prefix
jarExecutionCommand=$prefix$command$suffix
# Execute
$jarExecutionCommand

exit 0