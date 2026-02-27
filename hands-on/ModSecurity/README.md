> [!TIP]
> # Configuring a Open-Source Web Application Firewall on Debian
> • Created by allexBR<br/>
> • Sources: https://github.com/owasp-modsecurity/ModSecurity<br/>
>            https://github.com/owasp-modsecurity/ModSecurity-nginx<br/>
>            https://github.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker<br/>
>            https://blog.nginx.org/blog/compiling-and-installing-modsecurity-for-open-source-nginx
---

<br/>

### # INSTRUCTIONS FOR DEPLOY THE MODSECURITY WAF
<br/>

> Libmodsecurity is one component of the ModSecurity v3 project. The library codebase serves as an interface to ModSecurity Connectors taking in web traffic and applying traditional ModSecurity processing. In general, it provides the capability to load/interpret rules written in the ModSecurity SecRules format and apply them to HTTP content provided by your application via Connectors.<br/>
<br/>

> [!IMPORTANT]
> ### Nginx installation is required:
> Install Nginx using the following command:
```
wget https://raw.githubusercontent.com/allexBR/cheatsheets/main/hands-on/Nginx/install-nginx.sh
```
```
chmod +x install-nginx.sh
```
```
bash install-nginx.sh
```
<br/>

### • Install required libraries and packages:
> Before starting the compilation process, make sure that you have all the dependencies in place.
```
apt install -y apt-utils \
autoconf \
automake \
build-essential \
git \
libcurl4-openssl-dev \
libgd-dev
libgeoip-dev \
liblmdb-dev \
libpcre2-dev \
libpcre3-dev \
libssl-dev \
libtool \
libxml2-dev \
libxslt1-dev \
libyajl-dev \
pkgconf \
zlib1g-dev
```
<br/>

### • Download and Compile ModSecurity v3
>Please note that if you are working with git, don't forget to initialize and update the submodules. Here's a quick how-to:
```
cd /tmp
```
```
git clone --depth 1 -b v3/master --single-branch https://github.com/owasp-modsecurity/ModSecurity
```
```
cd ModSecurity/
```
```
git submodule init
```
```
git submodule update
```
```
./build.sh
```
```
./configure
```
```
make
```
```
make install
```
```
cd ..
```
<br/>

### • Download and Compile ModSecurity v3 Nginx Connector (compilation as a dynamic module):
> Download the source code corresponding to the installed version of NGINX (the complete sources are required even though only the dynamic module is being compiled).
```
git clone --depth 1 https://github.com/owasp-modsecurity/ModSecurity-nginx.git
```
> The script below downloads the Nginx source code from official repository and extracts all the compressed files into a .tar.gz archive.
```
wget https://raw.githubusercontent.com/allexBR/cheatsheets/main/hands-on/Nginx/download-nginx-source-code.sh
```
```
chmod +x download-nginx-source-code.sh
```
```
bash download-nginx-source-code.sh
```
```
cd /tmp/nginx-1.28.2
```
```
./configure --with-compat --add-dynamic-module=../ModSecurity-nginx
```
```
make modules
```
```
cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules
```
```
cd ..
```
<br/>

### • Load ModSecurity Module into Nginx:
> Add the following load_module directive to the main (top‑level) context in /etc/nginx/nginx.conf. It instructs NGINX to load the ModSecurity dynamic module when it processes the configuration.
```
load_module modules/ngx_http_modsecurity_module.so;
```
> [!NOTE]
> user nginx;
> worker_processes auto;<br/>
> ### load_module modules/ngx_http_modsecurity_module.so;<br/>

> pid /run/nginx.pid;
> include /etc/nginx/modules-enabled/*.conf;<br/>

> events {
>	worker_connections 1024;
>	# multi_accept on;
>}

<br/>
<br/>

---

<br/>
<br/>

### # INSTRUCTIONS FOR THE NGINX BAD BOT BLOCKER
<br/>

> [!NOTE]
> The Ultimate Nginx Bad Bot, User-Agent, Spam Referrer Blocker, Adware, Malware and Ransomware Blocker, Clickjacking Blocker, Click Re-Directing Blocker, SEO Companies and Bad IP Blocker with Anti DDOS System, Nginx Rate Limiting and Wordpress Theme Detector Blocking. Stop and Block all kinds of bad internet traffic even Fake Googlebots from ever reaching your web sites.
<br/>

### • Step 1:
```
curl -sL https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/install-ngxblocker -o /usr/local/sbin/install-ngxblocker
```
or
```
wget https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/install-ngxblocker -O /usr/local/sbin/install-ngxblocker
```
```
chmod +x /usr/local/sbin/install-ngxblocker
```

### • Step 2:
```
cd /usr/local/sbin
```
```
sudo ./install-ngxblocker
```

### • Step 3:
```
cd /usr/local/sbin/
```
```
sudo ./install-ngxblocker -x
```

### • Step 4:
```
cd /usr/local/sbin/
```
```
sudo ./setup-ngxblocker
```

### • Step 5:
```
cd /usr/local/sbin/
```
```
sudo ./setup-ngxblocker -x
```
  
### • Step 6:
```
sudo nginx -t
```
```
sudo nginx -t && sudo nginx -s reload
```
```
sudo service nginx restart
```

### • Step 7:
```
sudo crontab -e
```
```
00 22 * * * sudo /usr/local/sbin/update-ngxblocker -e yourname@youremail.com
```
<br/>
<br/>
<br/>
