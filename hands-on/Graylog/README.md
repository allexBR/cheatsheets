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

### # Implementation

This guide describes the recommended way to install Graylog on Debian Linux 13 (Trixie).<br/>

All links and packages are present at the time of writing.<br/>

These installation steps also include installation of OpenSearch so that you can manage your search backend manually.
<br/>

<br/>


***Prerequisites:***
<br/>

<img width="1189" height="548" alt="image" src="https://github.com/user-attachments/assets/f68809d5-aedd-41c7-adcd-e381a543be32" /><br/>

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
apt install apt-transport-https gnupg curl sudo
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
<br/>

• Enable the system service:
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
apt install -y lsb-release ca-certificates curl gnupg2
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
{ printf '%s\n' . + - '*'; shuf -e {A..H} {J..N} {P..Z} {a..h} {j..k} {m..n} {p..z} {2..9} -n28; } | shuf | tr -d '\n'; echo
```
<br/>

• Install OpenSearch 2.19.5:
```
OPENSEARCH_INITIAL_ADMIN_PASSWORD=<custom-admin-password> apt -y install opensearch=2.19.5
```
<br/>

• Hold the currently installed version of the OpenSearch package to prevent it from being automatically upgraded to a newer version when updates are installed:
```
apt-mark hold opensearch
```
<br/>

• OpenSearch configuration for Graylog:
```
nano /etc/opensearch/opensearch.yml
```

Update the following fields for a minimum unsecured running state (single node):
```
cluster.name: graylog
node.name: graylog-indexer
path.data: /var/lib/opensearch
path.logs: /var/log/opensearch
discovery.type: single-node
network.host: 0.0.0.0
action.auto_create_index: false
plugins.security.disabled: true
```
<br/>

• Enable JVM options:
```
nano /etc/opensearch/jvm.options
```

Now, update the Xms and Xmx settings with half of the installed system memory, like shown in the example below:
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
-Xms2g
-Xmx2g
```
<br/>

• Configure the kernel parameters at runtime:
```
sysctl -w vm.max_map_count=262144
echo 'vm.max_map_count=262144' >> /etc/sysctl.conf
```
<br/>

• Enable the system service:
```
systemctl daemon-reload
systemctl enable opensearch.service
systemctl start opensearch.service
```
<br/>

<br/>

---

***Graylog deployment***
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
apt install graylog-server uuid-runtime openjdk-21-jdk-headless
```
<br/>

• Set the `http_bind_address` value so that Graylog listens on all interfaces:
```
sed -i.bak 's/#http_bind_address = 127.0.0.1.*/http_bind_address = 0.0.0.0:9000/g' /etc/graylog/server/server.conf
```
<br/>

• Use the following command to create your `password_secret` for Graylog and make a note of it:
```
< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c${1:-96};echo;
```
<br/>

• Generate a custom admin password for Graylog:
```
{ printf '%s\n' . + - '*'; shuf -e {A..H} {J..N} {P..Z} {a..h} {j..k} {m..n} {p..z} {2..9} -n28; } | shuf | tr -d '\n'; echo
```
<br/>

• Use the following command to create your `root_password_sha2` and provide the alphanumeric password created in the previous step:
```
echo -n "Enter Password: " && head -1 </dev/stdin | tr -d '\n' | sha256sum | cut -d" " -f1
```
<br/>

> [!WARNING]
> Add `password_secret` and `root_password_sha2` values to the configuration file<br/>
> as these are mandatory and Graylog will not start without them.
<br/>

• Edit the Graylog Configuration File:
```
nano /etc/graylog/server/server.conf
```
Look for the following lines in the Graylog configuration file (server.conf) and provide the data generated in the previous steps.

password_secret = 

root_password_sha2 = 

elasticsearch_hosts = `http://admin:<opensearch-admin-password>@127.0.0.1:9200`

<br/>

• Finally, enable the system service:
```
systemctl daemon-reload
systemctl enable graylog-server.service
systemctl start graylog-server.service
systemctl --type=service --state=active | grep graylog
```
<br/>

• Prevent accidental updates on the Graylog server:
```
apt-mark hold graylog-server
```
<br/>

<br/>

---

***Graylog WebGUI HTTPS***
<br/>
<br/>

• Download and install latest stable Nginx via script:
```
cd /tmp && wget https://raw.githubusercontent.com/allexBR/cheatsheets/main/hands-on/Nginx/install-nginx.sh
```
```
chmod 744 install-nginx.sh
```
```
bash install-nginx.sh
```
<br/>

• Download and install Graylog SSL/TLS certificate:
```
cd /tmp && wget https://raw.githubusercontent.com/allexBR/cheatsheets/main/hands-on/Graylog/create-self-signed-cert-bundle.sh
```
```
chmod 744 create-self-signed-cert-bundle.sh
```
```
bash create-self-signed-cert-bundle.sh
```
<br/>

• Create a Nginx server block for Graylog:
```
nano /etc/nginx/conf.d/graylog.conf
```
```
server {
    listen 80;
    server_name app.graylog.local;
    # Redirect everything to HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}
server {
    listen 443 ssl;
    http2 on;
    server_name app.graylog.local;

    server_tokens off;

    access_log  /var/log/nginx/graylog.access.log  main;

    # SSL/TLS certs path
    ssl_certificate     /etc/ssl/certs/graylog.pem;
    ssl_certificate_key /etc/ssl/private/graylog.key;

    # SSL/TLS security settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    #ssl_ciphers HIGH:!aNULL:!MD5:!SHA;
    ssl_prefer_server_ciphers on;

    ##############################
    #--- Graylog Server HTTPS ---#
    ##############################
    location / {
        # Internal address where Graylog is running
        proxy_pass http://127.0.0.1:9000/;
        # Critical headers for Graylog working over HTTPS
        proxy_set_header Host $http_host;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Server $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Graylog-Server-URL https://$server_name/;
        # Avoids problems with WebSockets and long connection times
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        # Buffer and Timeouts for large searches
        proxy_read_timeout 90;
        proxy_connect_timeout 90;
    }

    ##########################
    #--- Security headers ---#
    ##########################

    # Content Security Policy (CSP)
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; connect-src 'self'; frame-ancestors 'self' *.graylog.org *.graylog.com; frame-src 'self' *.graylog.org *.graylog.com;" always;
    # Clickjacking protection
    add_header X-Frame-Options "SAMEORIGIN" always;
    # MIME type protection (Sniffing)
    add_header X-Content-Type-Options "nosniff" always;
    # Cross-Site Scripting protection (XSS)
    add_header X-XSS-Protection "1; mode=block" always;
    # Referrer Policy
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    # Hardware Resource Restriction (Permissions Policy)
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
}
```
<br/>

• Test and restart Nginx service:
```
nginx -t -c /etc/nginx/nginx.conf
```
```
systemctl restart nginx
```
<br/>

• Edit the Graylog configuration file:
```
nano /etc/graylog/server/server.conf
```
```
http_bind_address = 127.0.0.1:9000

http_publish_uri = http://127.0.0.1:9000/

http_external_uri = https://app.graylog.local/

http_non_proxy_hosts = app.graylog.local
```
<br/>

• Restart service:
```
systemctl restart graylog-server
```
<br/>
