> [!TIP]
> # Integration with Yeti - Your Everyday Threat Intelligence
> • Created by allexBR<br/>
> • Source: https://wazuh.com/blog/integrating-wazuh-with-yeti-platform/
---

<br/>

> ### # About
> Yeti aims to bridge the gap between CTI and DFIR practitioners by providing a Forensics Intelligence platform and pipeline for DFIR teams. It was born out of frustration of having to answer the question "where have I seen this artifact before?" or "how do I search for IOCs related to this threat (or all threats?) in my timeline?"
> 
> In a nutshell, Yeti allows you to:
>
> • Bulk search observables and get a pretty good guess on the nature of the threat, and how to find it on a system.
> 
> • Inversely, focus on a threat and quickly list all TTPs, malware, and related DFIR artifacts.
> 
> • Let CTI analysts focus on adding intelligence rather than worrying about machine-readable export formats.
> 
> • Incorporate your own data sources, analytics, and logic very easily.
> 
> This is done by:
> 
> • Storing technical and tactical CTI (observables, TTPs, campagins, etc.) from internal or external systems.
> 
> • Being a backend for DFIR-related queries: Yara signatures, Sigma rules, DFIQ.
> 
> • Providing a web API to automate queries (think incident management platform) and enrichment (think malware sandbox).
> 
> • Export the data in user-defined formats so that they can be ingested by third-party applications (SIEM, DFIR platforms).
> 
<br/>
<br/>

### # Requirements

• Yeti instance up and running.

• Yeti API Token.

• Enter the IP address of your Yeti instance in the `YETI_INSTANCE = 'http://<YETI_IP_ADDRESS>'` field located in the `custom-yeti.py` file.

<br/>
<br/>

### # Implementation

<br/>
<br/>

• Download the integration script file
```
wget -P /var/ossec/integrations/ https://raw.githubusercontent.com/allexBR/cheatsheets/main/hands-on/Wazuh/integrations/yeti/custom-yeti.py
```
<br/>

• Modifying required permissions
```
chmod 750 /var/ossec/integrations/custom-yeti.py
chown root:wazuh /var/ossec/integrations/custom-yeti.py
```
<br/>

• Modifying configuration file

Open the ossec.conf file and insert the integration block shown below to forward the hash to the MalwareBazaar API.

```
nano /var/ossec/etc/ossec.conf
```
```
  <!-- YETI Threat Intel Integration -->
  <integration>
    <name>custom-yeti.py</name>
    <api_key>YETI_API_KEY</api_key>
    <group>syscheck,attack,sshd,ids</group>
    <alert_format>json</alert_format>
  </integration>
```
<br/>

• Download the XML rules file
```
wget -P /var/ossec/etc/rules/ https://raw.githubusercontent.com/allexBR/cheatsheets/main/hands-on/Wazuh/integrations/yeti/yeti_rules.xml
```
<br/>

• Modifying required permissions
```
chmod 660 /var/ossec/etc/rules/yeti_rules.xml
chown wazuh:wazuh /var/ossec/etc/rules/yeti_rules.xml
```
<br/>

• Restart Wazuh Service

After applying the configuration, you must restart the Wazuh manager:

```
systemctl restart wazuh-manager
```
<br/>
