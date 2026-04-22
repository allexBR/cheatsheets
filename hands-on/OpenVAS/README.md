> [!TIP]
> # Building a Powerful Open Source Vulnerability Scanner
> <br/>
> • Sources: https://github.com/Kastervo/OpenVAS-Installation<br/>
>            https://greenbone.github.io/docs/latest/background.html<br/>
>            https://docs.greenbone.net/GSM-Manual/gos-24.10/en/
---

<br/>

### # INSTRUCTIONS FOR DEPLOY THE OPENVAS ON DEBIAN 13 (TRIXIE)
<br/>

> [!IMPORTANT]
> The shell script available in this repository was created and belongs to the company KASTERVO LTD. following Greenbone Community Edition guidelines. Therefore, it is copyrighted and all credit goes to the company KASTERVO LTD. for their dedication and excellent work!<br/>
> <br/>
> There were no drastic modifications to the source code. I just made subtle portability corrections so that the script also works on Debian 13 (Trixie), as it is more current.<br/>
<br/>

```
cd /tmp && wget https://raw.githubusercontent.com/allexBR/cheatsheets/main/hands-on/OpenVAS/openvas_install.sh
```
```
chmod +x openvas_install.sh
```
```
bash openvas_install.sh
```
<br/>
<br/>

> [!NOTE]
> Before attempting to create a new Task in OpenVAS, it is necessary to update the databases.<br/>
<br/>

• Update Network Vulnerability Tests (NVTs):
```
sudo -u gvm greenbone-feed-sync --type nvt
```
• Update Common Configuration Enumeration (SCAP) data:
```
sudo -u gvm greenbone-feed-sync --type scap
```
• Update Security Advisory (CERT) data:
```
sudo -u gvm greenbone-feed-sync --type cert
```
<br/>

• After synchronization is complete, restart the services to ensure everything has loaded correctly:
```
sudo systemctl restart ospd-openvas
sudo systemctl restart gvmd
sudo systemctl restart gsad
```
<br/>
<br/>

• Quick Verification:
> To check if the feeds are finally "OK" and ready for use, you can list the available scan settings:
```
sudo -u gvm gvmd --get-scanners
```

> To see if the scan settings (Full and Fast, etc.) are already appearing:
```
sudo -u gvm gvmd --get-configs
```
<br/>
<br/>

> [!WARNING]
> If for some reason the .lock file has become "orphaned" (which is common after a sudden restart or power outage) and is preventing the database from updating, you can remove it manually.<br/>

• Stop services for safety reasons:
```
sudo systemctl stop gvmd
```
<br/>

• Remove the lock file:
```
sudo rm /var/lib/gvm/feed-update.lock
```
<br/>

• Try running the sync command again:
```
sudo -u gvm greenbone-feed-sync --type nvt
```
```
sudo -u gvm greenbone-feed-sync --type scap
```
```
sudo -u gvm greenbone-feed-sync --type cert
```
<br/>
<br/>
