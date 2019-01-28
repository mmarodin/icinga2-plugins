#!/bin/python
#------------
# Host notification script for Icinga2
# Customized for Icinga 2 v2.6.2, Graphite-Web v0.9.15 and Grafana v2.6.0
# v.20160504 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#
import os
import smtplib
import socket
import urllib2
from email.MIMEMultipart import MIMEMultipart
from email.MIMEText import MIMEText
from email.MIMEImage import MIMEImage

# User customization here
FROM = 'icinga@icinga2.fqdn.here'
SERVER = 'localhost'
USERNAME = ''
PASSWORD = ''
ICINGA2BASE = 'http://icinga2.fqdn.here/icingaweb2'
GRAFANABASE = 'http://grafana.fqdn.here:3000'
GRAFANADASHBOARD = 'yourdashboard'
GRAFANAVARHOST = 'var-HOST'
GRAFANATHEME = 'light'
GRAFANAAPIKEY = 'yourAPIkey'
WIDTH = '640'
HEIGHT = '321'
COLUMN = '144'
DIFFERENCE = str(int(WIDTH) - int(COLUMN))


NOTIFICATIONTYPE = os.getenv('NOTIFICATIONTYPE', 'none')
HOSTALIAS = os.getenv('HOSTALIAS', 'none')
HOSTADDRESS = os.getenv('HOSTADDRESS', HOSTALIAS)
HOSTSTATE = os.getenv('HOSTSTATE', 'none')
LONGDATETIME = os.getenv('LONGDATETIME', 'none')
HOSTOUTPUT = os.getenv('HOSTOUTPUT', 'none')
NOTIFICATIONAUTHORNAME = os.getenv('NOTIFICATIONAUTHORNAME', 'none')
NOTIFICATIONCOMMENT = os.getenv('NOTIFICATIONCOMMENT', 'none')
HOSTDISPLAYNAME = os.getenv('HOSTDISPLAYNAME', 'none')
USEREMAIL = os.getenv('USEREMAIL', 'none')
HOSTPERFDATA = os.getenv('HOSTPERFDATA') # needs to be null to avoid it
HOSTURL = os.getenv('HOSTURL', 'none')
PANELURL = os.getenv('PANELURL') # no default initializer, this is optional

DEBUG = os.getenv('DEBUG')

TO = USEREMAIL
#TO = 'root@icinga2.fqdn.here'

# Logo for Icinga2 <= 2.5.x
# logoImagePath = '/usr/share/icingaweb2/public/img/logo_icinga-inv.png'
# Logo for Icinga2 >= 2.6.x
logoImagePath = '/usr/share/icingaweb2/public/img/icinga-logo.png'

if not HOSTADDRESS:
  HOSTADDRESS = HOSTALIAS

SUBJECTMESSAGE = NOTIFICATIONTYPE + ' - ' + HOSTDISPLAYNAME + ' is ' + HOSTSTATE

if PANELURL:
  GRAFANAPNG = GRAFANABASE + '/render/dashboard-solo/db/' + GRAFANADASHBOARD + '?fullscreen&panelId=' + PANELURL + '&' + GRAFANAVARHOST + '=' + HOSTURL + '&theme=' + GRAFANATHEME + '&width=' + WIDTH + '&height=' + HEIGHT
  GRAFANALINK = GRAFANABASE + '/dashboard/db/' + GRAFANADASHBOARD + '?fullscreen&panelId=' + PANELURL + '&' + GRAFANAVARHOST + '=' + HOSTURL

# Prepare mail body
TEXT = '***** Icinga  *****'
TEXT += '\n'
TEXT += '\nNotification Type: ' + NOTIFICATIONTYPE
TEXT += '\n'
TEXT += '\nHost: ' + HOSTALIAS
TEXT += '\nAddress: ' + HOSTADDRESS
TEXT += '\nState: ' + HOSTSTATE
TEXT += '\n'
TEXT += '\nDate/Time: ' + LONGDATETIME
TEXT += '\n'
TEXT += '\nAdditional Info: ' + HOSTOUTPUT
TEXT += '\n'
TEXT += '\nComment: [' + NOTIFICATIONAUTHORNAME + '] ' + NOTIFICATIONCOMMENT

HTML = '<html><head><style type="text/css">'
HTML += '\nbody {text-align: left; font-family: calibri, sans-serif, verdana; font-size: 10pt; color: #7f7f7f;}'
HTML += '\ntable {margin-left: auto; margin-right: auto;}'
HTML += '\na:link {color: #0095bf; text-decoration: none;}'
HTML += '\na:visited {color: #0095bf; text-decoration: none;}'
HTML += '\na:hover {color: #0095bf; text-decoration: underline;}'
HTML += '\na:active {color: #0095bf; text-decoration: underline;}'
HTML += '\nth {font-family: calibri, sans-serif, verdana; font-size: 10pt; text-align:left; white-space: nowrap; color: #535353;}'
HTML += '\nth.icinga {background-color: #0095bf; color: #ffffff; margin-left: 7px; margin-top: 5px; margin-bottom: 5px;}'
HTML += '\nth.perfdata {background-color: #0095bf; color: #ffffff; margin-left: 7px; margin-top: 5px; margin-bottom: 5px; text-align:center;}'
HTML += '\ntd {font-family: calibri, sans-serif, verdana; font-size: 10pt; text-align:left; color: #7f7f7f;}'
HTML += '\ntd.center {text-align:center; white-space: nowrap;}'
HTML += '\ntd.UP {background-color: #44bb77; color: #ffffff; margin-left: 2px;}'
#HTML += '\ntd.WARNING {background-color: #ffaa44; color: #ffffff; margin-left: 2px;}'
HTML += '\ntd.DOWN {background-color: #ff5566; color: #ffffff; margin-left: 2px;}'
HTML += '\ntd.UNREACHABLE {background-color: #aa44ff; color: #ffffff; margin-left: 2px;}'
HTML += '\n</style></head><body>'
HTML += '\n<table width=' + WIDTH + '>'

if os.path.exists(logoImagePath):
  HTML += '\n<tr><th colspan=2 class=icinga width=' + WIDTH +'><img src="cid:icinga2_logo"></th></tr>'

HTML += '\n<tr><th width=' + COLUMN + '>Notification Type:</th><td class=' + HOSTSTATE + '>' + NOTIFICATIONTYPE + '</td></tr>'
HTML += '\n<tr><th>Hostalias:</th><td><a style="color: #0095bf; text-decoration: none;" href="' + ICINGA2BASE +'/monitoring/host/show?host=' + HOSTALIAS + '">' + HOSTALIAS + '</a></td></tr>'
HTML += '\n<tr><th>IP Address:</th><td>' + HOSTADDRESS + '</td></tr>'
HTML += '\n<tr><th>Host Status:</th><td>' + HOSTSTATE + '</td></tr>'
HTML += '\n<tr><th>Service Name:</th><td>ping4</td></tr>'
HTML += '\n<tr><th>Service Data:</th><td><a style="color: #0095bf; text-decoration: none;" href="' + ICINGA2BASE + '/monitoring/host/services?host=' + HOSTALIAS + '">' + HOSTOUTPUT + '</a></td></tr>'
HTML += '\n<tr><th>Event Time:</th><td>' + LONGDATETIME + '</td></tr>'

if (NOTIFICATIONAUTHORNAME and NOTIFICATIONCOMMENT):
  HTML += '\n<tr><th>Comment:</th><td>' + NOTIFICATIONCOMMENT + ' (' + NOTIFICATIONAUTHORNAME + ')</td></tr>'

if (HOSTPERFDATA or PANELURL):
  HTML += '\n</table><br>'
  HTML += '\n<table width=' + WIDTH + '>'
  HTML += '\n<tr><th colspan=6 class=perfdata>Performance Data</th></tr>'
  if (HOSTPERFDATA):
    HTML += '\n<tr><th>Label</th><th>Last Value</th><th>Warning</th><th>Critical</th><th>Min</th><th>Max</th></tr>'
    PERFDATALIST = HOSTPERFDATA.split(" ")
    for PERFDATA in PERFDATALIST:
      if '=' not in PERFDATA:
        continue

      (LABEL,DATA) = PERFDATA.split("=")
      if (len(DATA.split(";")) is 5):
        (VALUE,WARNING,CRITICAL,MIN,MAX) = DATA.split(";")
      else:
        (VALUE,WARNING,CRITICAL,MIN) = DATA.split(";")
        MAX = ''
      HTML += '\n<tr><td>' + LABEL + '</td><td>' + VALUE + '</td><td>' + WARNING + '</td><td>' + CRITICAL + '</td><td>' + MIN + '</td><td>' + MAX + '</td></tr>'
  else:
    HTML += '\n<tr><th width=' + COLUMN + ' colspan=1>Last Value:</th><td width=' + DIFFERENCE + ' colspan=5>none</td></tr>'

if PANELURL:
  HTML += '\n<tr><td colspan=6><a href="' + GRAFANALINK + '"><img src="cid:grafana2_perfdata" width=' + WIDTH + ' height=' + HEIGHT + '></a></td></tr>'

HTML += '\n</table><br>'
HTML += '\n<table width=' + WIDTH + '>'
HTML += '\n<tr><td class=center>Generated by Icinga 2 and Grafana</td></tr>'
HTML += '\n</table><br>'
HTML += '\n</body></html>'

if DEBUG:
  print HTML

# Prepare email
msgRoot = MIMEMultipart('related')
msgRoot['Subject'] = SUBJECTMESSAGE
msgRoot['From'] = FROM
msgRoot['To'] = TO
msgRoot.preamble = 'This is a multi-part message in MIME format.'

msgAlternative = MIMEMultipart('alternative')
msgRoot.attach(msgAlternative)

msgText = MIMEText(TEXT)
msgAlternative.attach(msgText)

msgText = MIMEText(HTML, 'html')
msgAlternative.attach(msgText)

# Attach images
if os.path.exists(logoImagePath):
  fp = open(logoImagePath, 'rb')
  msgImage = MIMEImage(fp.read())
  fp.close()
  msgImage.add_header('Content-ID', '<icinga2_logo>')
  msgRoot.attach(msgImage)

if PANELURL:
  GET = urllib2.Request(GRAFANAPNG)
  GET.add_header('Authorization','Bearer ' + GRAFANAAPIKEY)
  GRAPH = urllib2.urlopen(GET)
  PNG = GRAPH.read()
  msgImage = MIMEImage(PNG)
  msgImage.add_header('Content-ID', '<grafana2_perfdata>')
  msgRoot.attach(msgImage)

# Send mail using SMTP
smtp = smtplib.SMTP()

try:
  smtp.connect(SERVER)
except socket.error as e:
  print "Unable to connect to SMTP server '" + SERVER + "': " + e.strerror
  os.sys.exit(e.errno)


if (USERNAME and PASSWORD):
  smtp.login(USERNAME, PASSWORD)

try:
  smtp.sendmail(FROM, TO, msgRoot.as_string())
  smtp.quit()
except Exception as e:
  print "Cannot send mail using SMTP: " + e.message
  os.sys.exit(e.errno)

os.sys.exit(0)
