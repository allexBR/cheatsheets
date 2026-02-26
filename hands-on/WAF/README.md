> [!TIP]
> # Configuring a Open-Source Web Application Firewall on Debian
> • Created by allexBR<br/>
> • Sources: https://github.com/owasp-modsecurity/ModSecurity-nginx<br/>
>            https://github.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker<br/>
>            https://blog.nginx.org/blog/compiling-and-installing-modsecurity-for-open-source-nginx

<br/>

### INSTRUCTIONS FOR DEPLOY THE MODSECURITY WAF
<br/>

> Libmodsecurity is one component of the ModSecurity v3 project. The library codebase serves as an interface to ModSecurity Connectors taking in web traffic and applying traditional ModSecurity processing. In general, it provides the capability to load/interpret rules written in the ModSecurity SecRules format and apply them to HTTP content provided by your application via Connectors.<br/>

> [!IMPORTANT]
> ### Nginx installation is required:
```
wget https://raw.githubusercontent.com/allexBR/cheatsheets/main/hands-on/Nginx/install-nginx.sh
chmod +x install-nginx.sh
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

### • Download and Compile ModSecurity v3
>Please note that if you are working with git, don't forget to initialize and update the submodules. Here's a quick how-to:
```
cd /tmp
git clone --depth 1 -b v3/master --single-branch https://github.com/owasp-modsecurity/ModSecurity
cd ModSecurity/
git submodule init
git submodule update
./build.sh
./configure
make
make install
cd ..
```

### • ModSecurity NGINX connector (compilation as a dynamic module):
```
git clone --depth 1 https://github.com/owasp-modsecurity/ModSecurity-nginx.git
nginx -v
wget https://nginx.org/download/nginx-1.28.2.tar.gz
tar zxvf nginx-*.tar.gz
cd nginx-1.*
./configure --with-compat --add-dynamic-module=../ModSecurity-nginx
make modules
cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules
cd ..
```

<br/>
<br/>

---

<br/>
<br/>

### INSTRUCTIONS FOR THE NGINX BAD BOT BLOCKER

### • Step 1:
```
curl -sL https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/install-ngxblocker -o /usr/local/sbin/install-ngxblocker
or
wget https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/install-ngxblocker -O /usr/local/sbin/install-ngxblocker

chmod +x /usr/local/sbin/install-ngxblocker
```

### • Step 2:
```
cd /usr/local/sbin

sudo ./install-ngxblocker
```

### • Step 3:
```
cd /usr/local/sbin/

sudo ./install-ngxblocker -x
```

### • Step 4:
```
cd /usr/local/sbin/

sudo ./setup-ngxblocker
```

### • Step 5:
```
cd /usr/local/sbin/

sudo ./setup-ngxblocker -x
```
  
### • Step 6:
```
sudo nginx -t

sudo nginx -t && sudo nginx -s reload

sudo service nginx restart
```

### • Step 7:
```
sudo crontab -e

00 22 * * * sudo /usr/local/sbin/update-ngxblocker -e yourname@youremail.com
```


> [!TIP]
> Helpful advice for doing things better or more easily.
> 

> [!NOTE]
> Notes...
