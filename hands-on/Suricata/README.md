> [!TIP]
> # Building a Robust Network Security Monitor with Deep Packet Inspection
> • Created by allexBR<br/>
> • Sources: https://www.ntop.org/guides/ntopng/third_party_integrations/suricata.html<br/>
>            https://www.ntop.org/support/documentation/software-installation/<br/>
>            https://community.emergingthreats.net/t/how-to-integrate-suricata-events-and-ntopng/889
---

<br/>

### # INSTRUCTIONS FOR DEPLOY SURICATA + NTOPNG
<br/>

> [!ATTENTION]
> To proceed with the steps below, will need to install Suricata first!
> To do this, use the automated installation script available in this repository!
<br/>
<br/>

> # About:
> ntopng® is a free software for monitoring traffic on a computer network. Is a web-based network traffic monitoring application released under GPLv3. It is the new incarnation of the original ntop written in 1998, and now revamped in terms of performance, usability, and features.<br/>
>
> ntopng® is able to:<br/>
> • Passive monitor traffic by passively capturing network traffic<br/>
> • Collect network flows (NetFlow, sFlow and IPFIX)<br/>
> • Actively monitor selected network devices<br/>
> • Monitor a network infrastructure via SNMP<br/>
>
> The main difference between ntopng and a traffic collector, is that ntopng not only reports traffic statistics but it also analizes the traffic, draws conclusions on observed traffic type and reports cybersecurity metrics.<br/>
>
> <img width="1577" height="1086" alt="image" src="https://github.com/user-attachments/assets/3fd57fa0-c9c5-453e-a831-74c128697529" />

<br/>
<br/>

> [!IMPORTANT]
> Before installing the ntop repository make sure to edit /etc/apt/sources.list
> and add 'contrib' at the end of each line that begins with 'deb' and 'deb-src'.
> 
<br/>

### • Add ntop repository:
```
cd /tmp && wget https://packages.ntop.org/apt-stable/trixie/all/apt-ntop-stable.deb
```
```
apt install ./apt-ntop-stable.deb
```
<br/>

### • Add Redis repository:
```
apt install -y lsb-release curl gpg
```
```
curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
```
```
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list
```
```
apt update
```
<br/>

### • Install ntopng and required packages:
> Once the ntop repository has been added, you can run the following commands (as root) to install ntop packages.
```
apt clean all ; apt update ; apt install -y pfring-dkms nprobe ntopng n2disk cento ntap
```
<br/>

### • Configure Ntopng to use the main network interface:
```
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)

echo "Starting Ntopng on the network interface: $INTERFACE"
```
<br/>

### • Create a syslog interface in ntopng.conf file:
> Performs a copy of the ntopng.yaml original file and apply the changes.
```
sed -i.bak \
    -e "/^-i=eth1/s/^/#/; /^-i=eth2/s/^/#/" \
    -e "/^#-i=eth2/a\-i=syslog:\/\/127.0.0.1:5140\n-i=$INTERFACE" \
    /etc/ntopng/ntopng.conf
```
<br/>

### • Changes default values (filetype and facility) in suricata.yaml:
```
sed -i \
    -e "/eve-log:/,/filetype:/ s/filetype: regular/filetype: syslog/" \
    -e "/eve-log:/,/facility:/ s/^[[:space:]]*#[[:space:]]*facility: local5/      facility: local0/" \
    /etc/suricata/suricata.yaml
```
<br/>

### • Rsyslog:
```
aapt install -y rsyslog
```
```
cat > /etc/rsyslog.d/99-suricata.conf <<EOF
if (\$syslogfacility-text == "local0") then {
    action(type="omfwd"
           target="127.0.0.1"
           port="5140"
           protocol="tcp"
           action.resumeRetryCount="100"
           queue.type="linkedList"
           queue.size="10000")
    stop
}
EOF
```
<br/>
