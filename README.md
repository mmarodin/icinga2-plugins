# icinga2-plugins
mmarodin's Icinga2 addons & plugins
they could work with other monitoring tools too (like Icinga v1, Nagios, Naemon, ...)

when possible I always use existing plugins, like Manubulon or Centreon plugins, or SNMP gets with the right OIDs
when it's not possible to do that, or if I could write a better plugin ... I'll do it! ;)

enjoy these plugins:
- Aerohive APs
- APC ATS and PDUs
- Aruba Networks switches
- Cisco Aironet APs
- DD-WRT APs
- Dell Powerconnect switches
- HWgroup sensors
- Linux systems
- Netapp storages
- Oracle VM manager and hypervisors
- pCOWeb sensors
- pfSense firewalls
- QNAP storages
- Socomec UPS
- Windows systems

see screenshots under folder's plugins for a quick view

try these funny addons to send HTML Icinga2 notifications via email with graphs:
- Notification (use Grafana via API to embed graphs)

then I create an new event handler to restart a service only if its state is CRITICAL
- EventHandlers