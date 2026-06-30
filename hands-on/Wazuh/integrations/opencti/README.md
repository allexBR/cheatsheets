> [!TIP]
> # Integration with OpenCTI - Threat Intelligence
> • Created by allexBR<br/>
> • Source: https://github.com/socfortress/Wazuh-Rules/tree/main/OpenCTI
---

<br/>

> ### # About
> OpenCTI is an open source platform allowing organizations to manage their cyber threat intelligence knowledge and observables. It has been created in order to structure, store, organize and visualize technical and non-technical information about cyber threats.
> 
> The structuration of the data is performed using a knowledge schema based on the STIX2 standards. It has been designed as a modern web application including a GraphQL API and a UX-oriented frontend. Also, OpenCTI can be integrated with other tools and applications such as MISP, TheHive, MITRE ATT&CK, etc.
<br/>
<br/>

### # Requirements

• OpenCTI instance up and running.

• OpenCTI API Token
.
• Root CA used to sign OpenCTI’s digital certificate (if HTTPS enabled).
<br/>
<br/>

### # Implementation

Wazuh-server will consume data stored in OpenCTI via its GraphQL API endpoint.

GraphQL is a query language for APIs and a runtime for fulfilling those queries with your existing data. The API query needs to be authenticated via an Auth HTTP header and the JSON body includes a query, values and search parameters.
<br/>
<br/>

• Download the integration script files.
```
wget -P /var/ossec/integrations/ https://raw.githubusercontent.com/allexBR/cheatsheets/main/hands-on/Wazuh/integrations/opencti/custom-opencti
```
```
wget -P /var/ossec/integrations/ https://raw.githubusercontent.com/allexBR/cheatsheets/main/hands-on/Wazuh/integrations/opencti/custom-opencti.py
```
<br/>

• Modifying required permissions
```
chmod 750 /var/ossec/integrations/custom-opencti
chown root:wazuh /var/ossec/integrations/custom-opencti
```
```
chmod 750 /var/ossec/integrations/custom-opencti.py
chown root:wazuh /var/ossec/integrations/custom-opencti.py
```
<br/>

• Modifying configuration file

Open the ossec.conf file and insert the integration block shown below.

```
nano /var/ossec/etc/ossec.conf
```
```
  <!-- OpenCTI Integration -->
  <integration>
    <name>custom-opencti</name>
    <group>sysmon_event1,sysmon_event3,sysmon_event6,sysmon_event7,sysmon_event_15,sysmon_event_22,syscheck</group>
    <alert_format>json</alert_format>
  </integration>
```
<br/>

• Download the XML rule file
```
wget -P /var/ossec/etc/rules/ https://raw.githubusercontent.com/allexBR/cheatsheets/main/hands-on/Wazuh/integrations/opencti/opencti_rules.xml
```
<br/>

• Modifying required permissions
```
chmod 660 /var/ossec/etc/rules/opencti_rules.xml
chown wazuh:wazuh /var/ossec/etc/rules/opencti_rules.xml
```
<br/>

• Restart Wazuh Service

After applying the configuration, you must restart the Wazuh manager:

```
systemctl restart wazuh-manager
```
<br/>
