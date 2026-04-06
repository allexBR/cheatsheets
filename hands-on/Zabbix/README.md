> [!TIP]
> # Deploying an Open Source Monitoring Platform with Zabbix
> • Created by allexBR<br/>
> • Sources: https://www.zabbix.com/download?zabbix=7.4&os_distribution=debian&os_version=13&components=server_frontend_agent&db=mysql&ws=nginx
---

<br/>

### # INSTRUCTIONS FOR INSTALL AND CONFIGURE ZABBIX ON DEBIAN
<br/>

> # About:
> Zabbix is an open-source monitoring platform for networks, servers, virtual machines, and cloud services. It collects metrics via SNMP, IPMI, JMX, and custom agents, then stores the data in a relational database and provides alerting, visualization, and reporting through a web-based frontend.<br/>
> ### Server and proxies:
> The Zabbix server collects data from agents and other sources, evaluates trigger conditions, sends alerts, and stores data in a relational database. Supported databases include PostgreSQL, MySQL/MariaDB, Oracle, and TimescaleDB (as a PostgreSQL extension for time-series optimization). For distributed monitoring, Zabbix proxies collect data at remote sites and forward it to the central server, reducing bandwidth and providing local buffering if the connection is interrupted.<br/>
> ### Agents:
> The original Zabbix agent (written in C) runs on Linux, Unix, Windows, and macOS, collecting system metrics such as CPU, memory, disk, and network statistics. Agent2 (written in Go) supports the same platforms and adds a plugin system for extending data collection to databases, message queues, and cloud APIs without writing external scripts.<br/>
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
<br/>

On Zabbix server host import initial schema and data. You will be prompted to enter your newly created password.
```
zcat /usr/share/zabbix/sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p zabbix
```
<br/>

Disable log_bin_trust_function_creators option after importing database schema.
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
Edit file /etc/zabbix/zabbix_server.conf
```
DBPassword=password
```
<br/>

### • Configure PHP for Zabbix frontend:
Edit file /etc/zabbix/nginx.conf uncomment and set 'listen' and 'server_name' directives.
```
# listen 8080;
# server_name example.com;
```
<br/>

### • Start Zabbix server and agent processes:
Start Zabbix server and agent processes and make it start at system boot.
```
systemctl restart zabbix-server zabbix-agent nginx php8.4-fpm
```
```
systemctl enable zabbix-server zabbix-agent nginx php8.4-fpm 
```
<br/>

### • Open Zabbix UI web page:
The URL for Zabbix UI when using Nginx depends on the configuration changes you should have made.
<br/>
<br/>
<br/>

### • Start using Zabbix:
Read in documentation: https://www.zabbix.com/documentation/7.4/en/manual/quickstart/login
<br/>
<br/>
<br/>

> [!NOTE]
> Data collection methods<br/>
> Zabbix supports multiple data collection protocols:<br/>
> • SNMP polling and traps for network equipment<br/>
> • IPMI for hardware health monitoring (temperature, fan speed, power)<br/>
> • JMX via the Java gateway for JVM metrics<br/>
> • HTTP/HTTPS for web scenario monitoring and REST API polling<br/>
> • SSH and Telnet for agentless checks on remote systems<br/>
> • Calculated and aggregated items for derived metrics<br/>
