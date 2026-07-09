> [!TIP]
> # Deploy a Free, Flexible and Open-source Powerful SIEM Solution with Graylog
> • Created by allexBR<br/>
> • Sources: https://graylog.org/products/source-available/<br/>
>            https://go2docs.graylog.org/current/what_is_graylog/what_is_graylog.htm
---

<br/>

> ### # About
> Graylog Open is a free, flexible and open-source powerful Security Information and Event Management (SIEM) solution and self-managed log analytics platform for cybersecurity teams, IT operations, or compliance, Graylog empowers teams with actionable insights through fast search, alerting, and visualization capabilities that want full control without a price tag.
> 
> Graylog Open centralizes, secures, and monitors machine-generated data across diverse sources. It’s backed by a vibrant community driving continuous innovation.
> 
> Collect, parse, enrich, search, analyze, and act on log data across your entire environment, on your terms!
> 
> Graylog delivers critical capabilities to support your security posture and IT operations such as:
> 
> • Data aggregation and enrichment
> 
> • Real-time threat detection and alerting
> 
> • Security analytics and dashboards
> 
> • Forensic and incident investigation
> 
> • User and entity behavior analytics (UEBA)
> 
> • IT compliance reporting
> 
> • Threat intelligence integration
> 
> • Event correlation and monitoring
<br/>
<br/>

## # Implementation

This guide describes the recommended way to install Graylog on Debian Linux 13 (Trixie).<br/>

All links and packages are present at the time of writing.<br/>

These installation steps also include installation of OpenSearch so that you can manage your search backend manually.
<br/>

<br/>


### * Prerequisites:
<br/>

<img width="1189" height="548" alt="image" src="https://github.com/user-attachments/assets/f68809d5-aedd-41c7-adcd-e381a543be32" /><br/>

<br/>
<br/>
<br/>

• Adjust the system time synchronization:
```
timedatectl set-timezone America/Sao_Paulo
```
```
nano /etc/systemd/timesyncd.conf
```
```
NTP=a.st1.ntp.br b.st1.ntp.br c.st1.ntp.br d.st1.ntp.br
FallbackNTP=0.br.pool.ntp.org 1.br.pool.ntp.org 2.br.pool.ntp.org 3.br.pool.ntp.org
```
<br/>

```
systemctl restart systemd-timesyncd
```
```
systemctl status systemd-timesyncd
```
<br/>

• Initial system repositories update and install required dependencies:
```
apt clean ; apt update ; apt upgrade
```
```
apt install curl apt-transport-https gnupg openjdk-21-jdk-headless dirmngr sudo
```
<br/>

• Install MongoDB:
```
sudo install -d -m 0755 /usr/share/keyrings
```
```
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
   sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg
```
```
echo "deb [signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
```
<br/>

• Update system repositories and install MongoDB
```
apt clean ; apt update
```
```
apt install -y mongodb-org
```
```
systemctl daemon-reload
systemctl enable mongod.service
systemctl restart mongod.service
systemctl --type=service --state=active | grep mongod
```
<br/>

• Download the XML rules file
```
wget -P /var/ossec/etc/rules/ https://raw.githubusercontent.com/allexBR/cheatsheets/main/hands-on/Wazuh/integrations/malwarebazaar/malwarebazaar_rules.xml
```
<br/>

• Modifying required permissions
```
chmod 660 /var/ossec/etc/rules/malwarebazaar_rules.xml
chown wazuh:wazuh /var/ossec/etc/rules/malwarebazaar_rules.xml
```
<br/>
