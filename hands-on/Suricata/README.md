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

> [!WARNING]
> To proceed with the steps below, will need to install Suricata first!<br/>
> To do this, use the automated installation script available in this repository!<br/>
```
wget https://raw.githubusercontent.com/allexBR/cheatsheets/main/hands-on/Suricata/install-suricata.sh
```
```
chmod +x install-suricata.sh
```
```
bash install-suricata.sh
```
<br/>
<br/>

> # About:
> The ntopng® is a free software for monitoring traffic on a computer network. Is a web-based network traffic monitoring application released under GPLv3. It is the new incarnation of the original ntop written in 1998, and now revamped in terms of performance, usability, and features.<br/>
>
> ntopng is able to:<br/>
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
> Before installing the ntop repository make sure to edit /etc/apt/sources.list<br/>
> and add 'contrib' (without quotation marks '') at the end of each line that begins with 'deb' and 'deb-src'.
> 
<br/>

### • Add ntop repository:
```
cd /tmp && wget https://packages.ntop.org/apt-stable/trixie/all/apt-ntop-stable.deb
```
```
apt install -y ./apt-ntop-stable.deb
```
<br/>

### • Add Redis repository:
```
apt update && apt install -y lsb-release curl gpg
```
```
curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
```
```
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | \
      tee /etc/apt/sources.list.d/redis.list
```
```
apt update
```
<br/>

### • Install ntopng and required packages:
> After adding the required repositories above, you must run the following commands (as root) to install the necessary applications.
```
apt clean all ; apt update ; apt install -y pfring-dkms nprobe ntopng n2disk cento ntap
```
<br/>

### • Ensure that ntopng is running the Community Edition version:
```
sed -i '1i --community\n' /etc/ntopng/ntopng.conf
```
```
systemctl restart ntopng
```
```
systemctl status ntopng
```
<br/>

### • Configure ntopng to use the main network interface:
> INTERFACE variable declaration is required for automatic configuration of the default network interface in the following steps.
```
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
```
```
echo "$INTERFACE"
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

### • Install Rsyslog and configure it to forward Suricata logs:
> The ntopng already includes a daemon able to listen for syslog logs on TCP or UDP at one (or more) configured endpoint.<br/>
> The log producer should be configured to send logs to that endpoint.In some cases (e.g. an IDS running on the same host)<br/>
> a syslog client like rsyslog should be installed and configured to export logs to ntopng.
```
apt update && apt install -y rsyslog
```
```
cat > /etc/rsyslog.d/99-remote.conf <<EOF
# Send Suricata alerts to ntopng
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

### • Restart the applications after configuration:
```
systemctl restart rsyslog ntopng suricata
```
<br/>

### • Validate Rsyslog settings:
```
rsyslogd -N1
```
<br/>

### • Configure HTTPS in ntopng:
> The certificate should be installed under the ntopng share directory, usually located at /usr/share/ntopng or at /usr/local/share/ntopng.
> The next instructions assume it’s located at /usr/share/ntopng/httpdocs/ssl (default path).
```
cd /tmp && wget https://raw.githubusercontent.com/allexBR/cheatsheets/main/hands-on/Suricata/create-ntopng-ssl-cert.sh
```
```
chmod +x ntopng-https.sh
```
```
bash ntopng-https.sh
```
<br/>

### • Add support for port 443/HTTPS to the ntopng config file:
```
sed -i '/-w=/a --http-port=0\n--https-port=443' /etc/ntopng/ntopng.conf
```
<br/>

### • Check if the TLS/SSL certificate is OK:
```
openssl ec -in /usr/share/ntopng/httpdocs/ssl/ntopng-cert.pem -check
```
<br/>

### • Restart ntopng again to apply all the changes made:
```
systemctl restart ntopng
```
<br/>

