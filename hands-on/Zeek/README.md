> [!TIP]
> # Deploying an Open Source Network Security Monitoring with Zeek
> • Created by allexBR<br/>
> • Sources: https://docs.zeek.org/en/current/<br/>
>            https://zeek.org/get-zeek/<br/>
>            https://wazuh.com/blog/network-security-monitoring-with-wazuh-and-zeek/
---

<br/>

### # INSTRUCTIONS FOR INSTALL THE ZEEK NETWORK MONITOR ON DEBIAN
<br/>

> # About:
> Zeek is a passive, open-source network traffic analyzer. Many operators use Zeek as a network security monitor (NSM) to support investigations of suspicious or malicious activity. The first benefit a new user derives from Zeek is the extensive set of logs describing network activity. In addition to the logs, Zeek comes with built-in functionality for a range of analysis and detection tasks, including extracting files from HTTP sessions, detecting malware by interfacing to external registries, reporting vulnerable versions of software seen on the network, identifying popular web applications, detecting SSH brute-forcing, validating SSL certificate chains, and much more.<br/>
<br/>

### • Run the command below to add the Zeek repository:
```
echo 'deb https://download.opensuse.org/repositories/security:/zeek/Debian_13/ /' | tee /etc/apt/sources.list.d/security:zeek.list
```
<br/>

### • Download and add the GPG key for the Zeek repository:
```
apt install -y lsb-release curl gpg
```
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
<br/>
<br/>

### # INSTRUCTIONS FOR CONFIGURE THE ZEEK NETWORK MONITOR
<br/>

### • Edit the /opt/zeek/etc/node.cfg file and set the packet capture interface:
> In this post, we use eth0.
```
[zeek]​
type=standalone​
host=localhost​
interface=eth0
```
<br/>

### • Edit the /opt/zeek/etc/networks.cfg file and add your subnet:
> Replace <NETWORK_SUBNET> with your network subnet. The content of the file will look similar to this:
```
# List of local networks in CIDR notation, optionally followed by a descriptive
# tag. Private address space defined by Zeek's Site::private_address_space set
# (see scripts/base/utils/site.zeek) is automatically considered local. You can
# disable this auto-inclusion by setting zeekctl's PrivateAddressSpaceIsLocal
# option to 0.
#
# Examples of valid prefixes:
#
# 1.2.3.0/24        Admin network
# 2607:f140::/32    Student network
<NETWORK_SUBNET>
```
<br/>

### • Run the following command to verify your Zeek syntax:
```
zeekctl check
```
<br/>

### • Set the main network interface in promiscuous mode:
This will allow Zeek to monitor and log events from all endpoints on the LAN.
```
ip link show
```
```
ip link show | grep PROMISC
```
```
nano /etc/network/interfaces
```
```
# The primary network interface
allow-hotplug enp0s3
iface enp0s3 inet static
    address 192.168.1.2
    netmask 255.255.255.0
    gateway 192.168.1.1
    # Put interfaces in promiscuous mode
    up ip link set enp0s3 promisc on
```
```
ifdown eth0 && ifup eth0
```
```
ip link show | grep PROMISC
```
<br/>

> [!NOTE]
> Hint: Run the zeekctl "deploy" command to get started.<br/>
> zeek scripts are ok.

<br/>

### • Start Zeek:
```
zeekctl deploy
```
<br/>

> [!NOTE]
> checking configurations ...<br/>
> installing ...<br/>
> creating policy directories ...<br/>
> installing site policies ...<br/>
> generating standalone-layout.zeek ...<br/>
> generating local-networks.zeek ...<br/>
> generating zeekctl-config.zeek ...<br/>
> generating zeekctl-config.sh ...<br/>
> stopping ...<br/>
> stopping zeek ...<br/>
> starting ...<br/>
> starting zeek ...
<br/>

### • Enable JSON log output:
> Zeek logs are stored in TSV format by default. Add the following line to the /opt/zeek/share/zeek/site/local.zeek file to generate logs in JSON format:

```
@load policy/tuning/json-logs.zeek
```
<br/>

### • Restart Zeek to apply the changes:
```
zeekctl deploy
```
<br/>
<br/>

> [!IMPORTANT]
> Zeek logs such as and will now be generated in JSON format in the directory /opt/zeek/logs/current<br/>
> - conn.log<br/>
> - dns.log<br/>
> - ssl.log

<img width="885" height="597" alt="image" src="https://github.com/user-attachments/assets/5400e532-827b-4876-96c2-b561f8d898ab" />



