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
```
systemctl restart systemd-timesyncd
```
```
systemctl status systemd-timesyncd
```
<br/>

• Initial update the system repositories and install required dependencies:
```
apt clean ; apt update ; apt upgrade
```
```
apt install curl apt-transport-https gnupg openjdk-21-jdk-headless dirmngr sudo
```
<br/>

• Create an APT repository for MongoDB:
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
```
apt clean ; apt update
```
<br/>

• Install latest stable MongoDB:
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

• Hold the currently installed version of the MongoDB to prevent it from being automatically upgraded to a newer version:
```
apt-mark hold mongodb-org
```
<br/>

<br/>

<br/>

• Install the necessary packages for OpenSearch deployment:
```
sudo apt-get update && sudo apt-get -y install lsb-release ca-certificates curl gnupg2
```
<br/>

• Create an APT repository for OpenSearch:
```
curl -o- https://artifacts.opensearch.org/publickeys/opensearch.pgp | sudo gpg --dearmor --batch --yes -o /usr/share/keyrings/opensearch-keyring
```
```
echo "deb [signed-by=/usr/share/keyrings/opensearch-keyring] https://artifacts.opensearch.org/releases/bundle/opensearch/2.x/apt stable main" | sudo tee /etc/apt/sources.list.d/opensearch-2.x.list
```
```
apt clean ; apt update
```
<br/>

• With the repository information added, list all available versions of OpenSearch:
```
apt list -a opensearch
```
<br/>

• Generate a custom admin password for OpenSearch:
```
chars='ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789.+-*'
printf '%s\n' "$chars" | grep -o . | shuf | head -n 32 | tr -d '\n'
echo
```
<br/>

• Install OpenSearch 2.19.5:
```
OPENSEARCH_INITIAL_ADMIN_PASSWORD=<custom-admin-password> apt -y install opensearch=2.19.5
```
<br/>

• Hold the currently installed version of the OpenSearch package to prevent it from being automatically upgraded to a newer version when updates are installed.
```
apt-mark hold opensearch
```
<br/>

• OpenSearch configuration for Graylog:
```
nano /etc/opensearch/opensearch.yml
```
<br/>

Update the following fields for a minimum unsecured running state (single node).
```
cluster.name: graylog
node.name: ${HOSTNAME}
path.data: /var/lib/opensearch
path.logs: /var/log/opensearch
discovery.type: single-node
network.host: 0.0.0.0
action.auto_create_index: false
plugins.security.disabled: true
```
<br/>

• Enable JVM options.
```
nano /etc/opensearch/jvm.options
```

Now, update the Xms and Xmx settings with half of the installed system memory, like shown in the example below.
```
## JVM configuration
################################################################
## IMPORTANT: JVM heap size
################################################################
##
## You should always set the min and max JVM heap
## size to the same value. For example, to set
## the heap to 4 GB, set:
##
## -Xms4g
## -Xmx4g
##
## See https://opensearch.org/docs/opensearch/install/important-settings/
## for more information
##
################################################################
# Xms represents the initial size of total heap space
# Xmx represents the maximum size of total heap space
-Xms1g
-Xmx1g
```
<br/>

• Configure the kernel parameters at runtime.
```
sysctl -w vm.max_map_count=262144
echo 'vm.max_map_count=262144' >> /etc/sysctl.conf
```
<br/>

• Finally, enable the system service.
```
systemctl daemon-reload
```
```
systemctl enable opensearch.service
```
```
systemctl start opensearch.service
```
<br/>

<br/>

• Create an APT repository for Graylog:
```
wget https://packages.graylog2.org/repo/packages/graylog-7.1-repository_latest.deb
```
```
dpkg -i graylog-7.1-repository_latest.deb
```
```
apt clean ; apt update
```
<br/>

• Install Graylog Open:
```
apt install graylog-server
```
<br/>

• Prevent accidental updates on the Graylog server:
```
apt-mark hold graylog-server
```
<br/>

