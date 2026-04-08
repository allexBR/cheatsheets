> [!TIP]
> # Deploying a NTP server
> • Created by allexBR<br/>
> • Sources: https://ntp.br/guia/linux/
---

<br/>

### # INSTRUCTIONS FOR INSTALL AND CONFIGURE NTP AND NTS WITH NTPsec ON DEBIAN
<br/>

> # About:
> NTPsec is a secure, enhanced, audited, simplified, and modern version of NTP. Derived from David Mills' NTP reference implementation. Supports NTS. It is recommended to be used for both client and server roles. Note that it is not recommended to use the reference implementation available in ntp.org.<br/>
> 
> NTPsec is a good choice for an NTP server, but for a host that only needs the client role, it is preferable to use Chrony. NTPSec will always open a socket and serve requests on UDP port 123, that is, it will always behave like a server as well. A stateful firewall or a network that uses NAT can prevent requests from reaching the computer. NTPSec does not yet support RFC 9109, that is, all client requests also have UDP port 123 as their source port. That is, the implementation uses UDP port 123 for both the source and destination of packets. This makes firewalls more complex in order to avoid their use as a server, leaving the options of using a stateful firewall, or using static rules that only allow packets destined for UDP port 123 coming from the servers used in the configuration.<br/>
> 
> For GNU/Linux, FreeBSD, OpenBSD, and other Unix-based systems, use the appropriate installation method for your distribution. Here the example uses apt, used in Linux distributions such as Debian and Ubuntu. There may be alternative methods for installation, so it is recommended to consult the documentation for your distribution or operating system.<br/>
<br/>

### • Install NTPsec:
```
apt clean && apt update && apt install -y ntpsec
```

After installing ntp, create the ntp.drift file with the command:
```
touch /var/lib/ntpsec/ntp.drift
```

The following recommendation for the configuration file for the NTP client (/etc/ntpsec/ntp.conf):
```
# This is the path to the tz database file that lists
# the leap seconds, check if the location is correct for your specific distribution
# or operating system, if not, adjust it
leapfile /usr/share/zoneinfo/leap-seconds.list

# "memory" for your clock's frequency error
driftfile /var/lib/ntpsec/ntp.drift

# If you wish to keep detailed logs
# Create the folder /var/log/ntpsec/ and uncomment the following lines
# statsdir /var/log/ntpsec/
# statistics loopstats peerstats clockstats
# filegen loopstats file loopstats type day enable
# filegen peerstats file peerstats type day enable
# filegen clockstats file clockstats type day enable

# Public NTP.br servers with NTS available
server a.st1.ntp.br iburst nts
server b.st1.ntp.br iburst nts
server c.st1.ntp.br iburst nts
server d.st1.ntp.br iburst nts
server e.st1.ntp.br iburst nts
server gps.nu.ntp.br iburst nts
server gps.jd.ntp.br iburst nts
server gps.ce.ntp.br iburst nts

# If you wish, you can configure additional servers with NTS, such as those from Cloudflare and Netnod.
# In this case, simply uncomment the following lines.
# server time.cloudflare.com iburst nts
# server nts.netnod.se iburst nts

# Access restriction settings
restrict default kod nomodify nopeer noquery limited
restrict 127.0.0.1
restrict ::1
```
<br/>

It is important to note that in NTPd it was necessary to add the line . It disabled the monlist command, which could be exploited to generate amplified denial-of-service attacks. This is not required in NTPsec. |disable monitor|<br/>
Note that NTPsec, like the original NTPd, still functions simultaneously as a client and server. In exclusive use as a client, it is important to configure a stateful firewall avoiding its use as a server. Or a static firewall that blocks all incoming packets to UDP port 123, with the exception of those originating from the servers configured in the ntp.conf file.<br/>
To restart the service you can use the following command, or see the appropriate instructions for your distribution or operating system:
```
service ntpsec restart
```
<br/>

To verify the correct operation and correctness of the time, as well as the use of NTS, the following commands can be used:
```
ntpq -c rl
```
```
ntpq -p
```
