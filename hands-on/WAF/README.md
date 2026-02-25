
# Configuring a Open-Source WAF on Debian Server

• Created by allexBR

• Sources: https://github.com/owasp-modsecurity/ModSecurity-nginx


https://github.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker

---

## INSTRUCTIONS FOR THE NGINX MODSECURITY



• Nginx installation is required:
 
wget https://raw.githubusercontent.com/allexBR/cheatsheets/main/hands-on/Nginx/install-nginx.sh

chmod +x install-nginx.sh

bash install-nginx.sh

--- 


• Install required libraries and packages:

apt install -y build-essential \
apt-utils \
autoconf \
automake \
git \
libcurl4-openssl-dev \
libpcre3-dev \
libssl-dev \
libxml2-dev \
libgeoip-dev \
liblmdb-dev \
libpcre2-dev \
libtool \
libxml2-dev \
libyajl-dev \
pkgconf \
zlib1g-dev \
libxslt1-dev \
libgd-dev


#ModSecurity compilation
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

git clone --depth 1 https://github.com/owasp-modsecurity/ModSecurity-nginx.git

nginx -v


---

## INSTRUCTIONS FOR THE NGINX BAD BOT BLOCKER

# Step 1:

curl -sL https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/install-ngxblocker -o /usr/local/sbin/install-ngxblocker

or

wget https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/install-ngxblocker -O /usr/local/sbin/install-ngxblocker


chmod +x /usr/local/sbin/install-ngxblocker


# Step 2:

cd /usr/local/sbin

sudo ./install-ngxblocker


# Step 3:

cd /usr/local/sbin/

sudo ./install-ngxblocker -x


# Step 4:

cd /usr/local/sbin/

sudo ./setup-ngxblocker


# Step 5:

cd /usr/local/sbin/

sudo ./setup-ngxblocker -x

  
# Step 6:

sudo nginx -t

sudo nginx -t && sudo nginx -s reload

sudo service nginx restart


# Step 7:

sudo crontab -e

00 22 * * * sudo /usr/local/sbin/update-ngxblocker -e yourname@youremail.com


