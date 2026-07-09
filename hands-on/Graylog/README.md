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

## # Implementation

This guide describes the recommended way to install Graylog on Debian Linux 13 (Trixie).<br/>

All links and packages are present at the time of writing.<br/>

These installation steps also include installation of OpenSearch so that you can manage your search backend manually.
<br/>

<br/>


### # Prerequisites:
<br/>

<img width="1189" height="548" alt="image" src="https://github.com/user-attachments/assets/f68809d5-aedd-41c7-adcd-e381a543be32" /><br/>

<br/>
<br/>
<br/>

• Adjust the system time synchronization:
```
nano /etc/systemd/timesyncd.conf
```
```
NTP=a.st1.ntp.br b.st1.ntp.br c.st1.ntp.br d.st1.ntp.br
FallbackNTP=0.br.pool.ntp.org 1.br.pool.ntp.org 2.br.pool.ntp.org 3.br.pool.ntp.org
```
<br/>

```
systemctl restart systemd-timesyncd
```
```
systemctl status systemd-timesyncd
```

• Download the integration script file
```
wget -P /var/ossec/integrations/ https://raw.githubusercontent.com/allexBR/cheatsheets/main/hands-on/Wazuh/integrations/malwarebazaar/custom-malwarebazaar.py
```
<br/>

• Modifying required permissions
```
chmod 750 /var/ossec/integrations/custom-malwarebazaar.py
chown root:wazuh /var/ossec/integrations/custom-malwarebazaar.py
```
<br/>

• Modifying configuration file

Open the ossec.conf file and insert the integration block shown below to forward the hash to the MalwareBazaar API.

```
nano /var/ossec/etc/ossec.conf
```
```
  <!-- MalwareBazaar Integration -->
  <integration>
    <name>custom-malwarebazaar.py</name>
    <hook_url>https://mb-api.abuse.ch/api/v1/</hook_url>
    <api_key>API_KEY</api_key> <!-- YOUR MALWARE BAZZAR API-->
    <rule_id>554</rule_id> <!-- ENTER THE RULE_ID -->
    <alert_format>json</alert_format>
  </integration>
```
<br/>

• Download the XML rules file
```
wget -P /var/ossec/etc/rules/ https://raw.githubusercontent.com/allexBR/cheatsheets/main/hands-on/Wazuh/integrations/malwarebazaar/malwarebazaar_rules.xml
```
<br/>

• Modifying required permissions
```
chmod 660 /var/ossec/etc/rules/malwarebazaar_rules.xml
chown wazuh:wazuh /var/ossec/etc/rules/malwarebazaar_rules.xml
```
<br/>
