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

Update Network Vulnerability Tests (NVTs):
```
sudo -u gvm greenbone-feed-sync --type nvt
```
Update Common Configuration Enumeration (SCAP) data:
```
sudo -u gvm greenbone-feed-sync --type scap
```
Update Security Advisory (CERT) data:
```
sudo -u gvm greenbone-feed-sync --type cert
```
<br/>
<br/>

After synchronization is complete, restart the services to ensure everything has loaded correctly:
```
sudo systemctl restart ospd-openvas
sudo systemctl restart gvmd
sudo systemctl restart gsad
```
<br/>
<br/>
