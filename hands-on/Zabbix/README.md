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
cd /tmp
```
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

### • Install MySQL repository:
```
apt update && apt install -y wget gnupg
```
```
wget https://repo.mysql.com//mysql-apt-config_0.8.36-1_all.deb
```
```
dpkg -i mysql-apt-config_0.8.36-1_all.deb
```
#### Fix Missing libaio1 Dependency

MySQL requires libaio1, which is no longer included in Debian 13.
We can install it from the Debian 12 (Bookworm) repository:
```
wget https://deb.debian.org/debian/pool/main/liba/libaio/libaio1_0.3.113-4_amd64.deb
```
```
apt install ./libaio1_0.3.113-4_amd64.deb
```
```
apt clean && apt update && apt install -y mysql-server
```
<br/>

### • Install PHP (ondrej/php) DPA repository:
PHP latest stable packages are not available in any of the current Debian or Ubuntu software repositories, the PHP packages must come from third-party repositories.

Ondřej Surý maintains a package archive that contains compiled binaries of all current PHP versions, for Ubuntu and Debian.
```
apt update && apt install -y lsb-release ca-certificates curl
```
```
curl -sSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb
```
```
dpkg -i /tmp/debsuryorg-archive-keyring.deb
```
```
sh -c 'echo "deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
```
```
apt clean && apt update
```
<br/>

### • Install Nginx repository:
```
apt update && apt install -y curl gnupg2 ca-certificates lsb-release debian-archive-keyring
```
```
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
```
```
mkdir -p /root/.gnupg
```
```
chown root:root /root/.gnupg && chmod 700 /root/.gnupg
```
```
gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg
```
The output should contain the full fingerprint 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 as follows:
Note that the output can contain other keys used to sign the packages.
```
pub   rsa2048 2011-08-19 [SC] [expires: 2027-05-24]
      573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62
uid                      nginx signing key <signing-key@nginx.com>
```
```
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
https://nginx.org/packages/debian `lsb_release -cs` nginx" \
    | tee /etc/apt/sources.list.d/nginx.list
```
```
tee /etc/apt/preferences.d/99nginx <<EOF
Package: *
Pin: origin nginx.org
Pin: release o=nginx
Pin-Priority: 900
EOF
```
```
apt clean && apt update
```
<br/>
<br/>

### • Install Zabbix server, frontend, agent:
```
apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-nginx-conf zabbix-sql-scripts zabbix-agent
```
<br/>

### • Create initial database:
```
mysql -uroot -p
```
> [!NOTE]
> Use the Delinea app via the link below to generate strong passwords.<br/>
> https://delinea.com/resources/password-generator-it-tool<br/>
<br/>

mysql>
```
create database zabbix character set utf8mb4 collate utf8mb4_bin;
```
```
create user zabbix@localhost identified by 'password';
```
```
grant all privileges on zabbix.* to zabbix@localhost;
```
```
set global log_bin_trust_function_creators = 1;
```
```
quit;
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
