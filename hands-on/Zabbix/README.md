> [!TIP]
> # Deploying an Open Source Monitoring Platform with Zabbix
> • Created by allexBR<br/>
> • Sources: https://www.zabbix.com/download?zabbix=7.4&os_distribution=debian&os_version=13&components=server_frontend_agent&db=mysql&ws=nginx
---

<br/>

### # INSTRUCTIONS FOR INSTALL AND CONFIGURE ZABBIX ON DEBIAN
<br/>

> About: Zabbix is an open-source monitoring platform for networks, servers, virtual machines, and cloud services. It collects metrics via SNMP, IPMI, JMX, and custom agents, then stores the data in a relational database and provides alerting, visualization, and reporting through a web-based frontend.<br/>
<br/>

### • Install Zabbix repository:
```
wget https://repo.zabbix.com/zabbix/7.4/release/debian/pool/main/z/zabbix-release/zabbix-release_latest_7.4+debian13_all.deb
```
```
dpkg -i zabbix-release_latest_7.4+debian13_all.deb
```
```
apt clean && apt update
```
<br/>

### • Install Zabbix server, frontend, agent:
```
apt install zabbix-server-mysql zabbix-frontend-php zabbix-nginx-conf zabbix-sql-scripts zabbix-agent
```
<br/>

### • Create initial database:
```
mysql -uroot -p
```
```
password
```
```
mysql> create database zabbix character set utf8mb4 collate utf8mb4_bin;
```
```
mysql> create user zabbix@localhost identified by 'password';
```
```
mysql> grant all privileges on zabbix.* to zabbix@localhost;
```
```
mysql> set global log_bin_trust_function_creators = 1;
```
```
mysql> quit;
```
> On Zabbix server host import initial schema and data. You will be prompted to enter your newly created password.
```
zcat /usr/share/zabbix/sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p zabbix
```
> Disable log_bin_trust_function_creators option after importing database schema.
```
mysql -uroot -p
```
```
password
```
```
mysql> set global log_bin_trust_function_creators = 0;
```
```
mysql> quit;
```
<br/>

### • Configure the database for Zabbix server:
> Edit file /etc/zabbix/zabbix_server.conf
```
DBPassword=password
```
<br/>

### • Configure PHP for Zabbix frontend:
> Edit file /etc/zabbix/nginx.conf uncomment and set 'listen' and 'server_name' directives.
```
# listen 8080;
# server_name example.com;
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



