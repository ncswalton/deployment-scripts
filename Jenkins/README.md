## Jenkins automation scripts

---
### `controller.sh`

Usage: `bash controller.sh [jenkinsUsername] [jenkinsPassword]`

**Software installation and configuration for a Jenkins Controller.**

- Currently URL of 10.5.0.4 hard-coded for simplicity
    - The script has been developed for Azure VMs. The Controller will always be the first resource in the subnet, which means it will be assigned 10.5.0.4 as a private IP.
- Full Name and Email fields of Jenkins admin user setup are unused.

---

### `agent.sh`

Usage: `bash agent.sh [ControllerIP] [jenkinsPassword] [username] [nodeName]`

**Software installation and configuration for a Jenkins Agent.**

- Assumes a single common username for Jenkins and the Agent VM.
- Configures an Agent and connects it to the Controller.
- Currently nodeName argument is unused. New node name is hard coded for testing.

---
### The code is based on this blog post

https://kevin-denotariis.medium.com/download-install-and-setup-jenkins-completely-from-bash-unlock-create-admin-user-and-more-debd3320414a
