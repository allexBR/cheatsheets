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
mysql>
```
set global log_bin_trust_function_creators = 0;
```
```
quit;
```
<br/>

### • Configure the database for Zabbix server:
Edit file /etc/zabbix/zabbix_server.conf
```
DBPassword=password
```
```
DBSocket=/var/run/mysqld/mysqld.sock
```
<br/>

### • Configure PHP for Zabbix frontend:
Edit file /etc/php/*/fpm/pool.d/www.conf comment and redifine 'user' and 'group' directives.
```
;user = www-data
;group = www-data

user = nginx
group = nginx
```

Edit file /etc/php/*/fpm/pool.d/zabbix-php-fpm.conf and redifine 'user', 'group', 'listen' and 'listen.owner' directives.
```
[zabbix]
user = nginx
group = nginx

listen = /run/php/zabbix.sock
listen.owner = nginx
listen.group = nginx
listen.mode = 0660
;listen.allowed_clients = 127.0.0.1

pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 200

php_value[session.save_handler] = files
php_value[session.save_path]    = /var/lib/php/sessions/

php_value[max_execution_time] = 300
php_value[memory_limit] = 128M
php_value[post_max_size] = 16M
php_value[upload_max_filesize] = 2M
php_value[max_input_time] = 300
php_value[max_input_vars] = 10000
```

Edit file /etc/zabbix/nginx.conf uncomment and set 'listen' and 'server_name' directives.
```
#       listen 8080;
#       server_name example.com;

        location ~ [^/]\.php(/|$) {
                fastcgi_pass    unix:/run/php/zabbix.sock;
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
Create a custom configuration file /usr/share/zabbix/ui/conf/zabbix.conf.php with the required parameters.
```
<?php
// Zabbix GUI configuration file.

$DB['TYPE']			= 'MYSQL';
$DB['SERVER']		= 'localhost';
$DB['PORT']			= '3306';
$DB['DATABASE']		= 'zabbix';
$DB['USER']			= 'zabbix';
$DB['PASSWORD']		= 'password';

// Schema name. Used for PostgreSQL.
$DB['SCHEMA']			= '';

// Used for TLS connection.
$DB['ENCRYPTION']		= false;
$DB['KEY_FILE']			= '';
$DB['CERT_FILE']		= '';
$DB['CA_FILE']			= '';
$DB['VERIFY_HOST']		= false;
$DB['CIPHER_LIST']		= '';

// Vault configuration. Used if database credentials are stored in Vault secrets manager.
$DB['VAULT']			= '';
$DB['VAULT_URL']		= '';
$DB['VAULT_PREFIX']		= '';
$DB['VAULT_DB_PATH']	= '';
$DB['VAULT_TOKEN']		= '';
$DB['VAULT_CERT_FILE']	= '';
$DB['VAULT_KEY_FILE']	= '';
// Uncomment to bypass local caching of credentials.
// $DB['VAULT_CACHE']	= true;

// Uncomment and set to desired values to override Zabbix hostname/IP and port.
// $ZBX_SERVER			= '';
// $ZBX_SERVER_PORT		= '';

$ZBX_SERVER_NAME		= 'zabbix-server';

$IMAGE_FORMAT_DEFAULT	= IMAGE_FORMAT_PNG;

// Uncomment this block only if you are using Elasticsearch.
// Elasticsearch url (can be string if same url is used for all types).
//$HISTORY['url'] = [
//	'uint' => 'http://localhost:9200',
//	'text' => 'http://localhost:9200'
//];
// Value types stored in Elasticsearch.
//$HISTORY['types'] = ['uint', 'text'];

// Used for SAML authentication.
// Uncomment to override the default paths to SP private key, SP and IdP X.509 certificates, and to set extra settings.
//$SSO['SP_KEY']		= 'conf/certs/sp.key';
//$SSO['SP_CERT']		= 'conf/certs/sp.crt';
//$SSO['IDP_CERT']		= 'conf/certs/idp.crt';
//$SSO['SETTINGS']		= [];

// If set to false, support for HTTP authentication will be disabled.
// $ALLOW_HTTP_AUTH = true;

$ZBX_SERVER_TLS['ACTIVE'] = '0';
$ZBX_SERVER_TLS['CA_FILE'] = '';
$ZBX_SERVER_TLS['KEY_FILE'] = '';
$ZBX_SERVER_TLS['CERT_FILE'] = '';
$ZBX_SERVER_TLS['CERTIFICATE_ISSUER']  = '';
$ZBX_SERVER_TLS['CERTIFICATE_SUBJECT'] = '';
```
<br/>

The URL for Zabbix UI when using Nginx depends on the configuration changes you should have made.
```
http://<IP-or-FQDN>:8080
```

<img width="377" height="420" alt="image" src="https://github.com/user-attachments/assets/0bf0d709-07e6-4b11-91b0-60978a402e62" />

This is the Zabbix welcome screen. Enter the user name Admin with password zabbix to log in as a Zabbix superuser.
Access to all menu sections will be granted.

For security reasons, it is strongly recommended to change the default password for the Admin account immediately after the first login.
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
<br/>
<br/>

### • Deploy agents:
Install Zabbix repository on Linux endpoints.
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
apt clean && apt update && apt install -y zabbix-agent
```
<br/>

Edit file /etc/zabbix/zabbix_agentd.conf
```
##### Passive checks related
### Option: Server
Server=192.168.1.1


##### Active checks related
### Option: ServerActive
ServerActive=192.168.1.1


### Option: Hostname
Hostname=Zabbix_endpoint_name
```
<br/>

Restart Zabbix-agent service.
```
systemctl restart zabbix-agent
```
<br/>
<br/>
