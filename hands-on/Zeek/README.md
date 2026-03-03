> [!TIP]
> # Deploying an Open Source Network Security Monitoring with Zeek on Debian Server
> • Created by allexBR<br/>
> • Sources: https://docs.zeek.org/en/current/<br/>
>            https://zeek.org/get-zeek/<br/>
>            https://wazuh.com/blog/network-security-monitoring-with-wazuh-and-zeek/
---

<br/>

### # INSTRUCTIONS FOR INSTALL THE ZEEK NETWORK MONITOR
<br/>

> Zeek is a passive, open-source network traffic analyzer. Many operators use Zeek as a network security monitor (NSM) to support investigations of suspicious or malicious activity. The first benefit a new user derives from Zeek is the extensive set of logs describing network activity. In addition to the logs, Zeek comes with built-in functionality for a range of analysis and detection tasks, including extracting files from HTTP sessions, detecting malware by interfacing to external registries, reporting vulnerable versions of software seen on the network, identifying popular web applications, detecting SSH brute-forcing, validating SSL certificate chains, and much more.<br/>
<br/>

### • Run the command below to add the Zeek repository:
```
echo 'deb https://download.opensuse.org/repositories/security:/zeek/Debian_13/ /' | tee /etc/apt/sources.list.d/security:zeek.list
```
<br/>

### • Download and add the GPG key for the Zeek repository:
```
curl -fsSL https://download.opensuse.org/repositories/security:/zeek/Debian_13/Release.key | \
gpg --dearmor | tee /etc/apt/trusted.gpg.d/security_zeek.gpg > /dev/null
```
<br/>

### • Update the repository index and install Zeek using the following command:
```
apt update
```
```
apt install zeek
```
<br/>

### • Add the /opt/zeek/bin directory to the system path through the ~/.bashrc file, then reload the ~/.bashrc file to apply the changes:
```
echo "export PATH=$PATH:/opt/zeek/bin" >> ~/.bashrc
```
```
source ~/.bashrc
```
<br/>

### • Verify the installed Zeek version:
```
zeek --version
```
<br/>

