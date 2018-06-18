#!/bin/python
#------------
# Service notification script for Icinga2
# v.20170310 by mmarodin
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
GRAFANADASHBOARDUID = 'yourdashboarduid'
GRAFANAVARHOST = 'var-hostname'
GRAFANAVARSERVICE = 'var-service'
GRAFANAVARCOMMAND = 'var-command'
GRAFANATHEME = 'light'
GRAFANAAPIKEY = 'yourAPIkey'
WIDTH = '640'
HEIGHT = '321'
COLUMN = '144'
DIFFERENCE = str(int(WIDTH) - int(COLUMN))

NOTIFICATIONTYPE = os.getenv('NOTIFICATIONTYPE', 'none')
SERVICEDESC = os.getenv('SERVICEDESC', 'none')
HOSTALIAS = os.getenv('HOSTALIAS', 'none')
HOSTADDRESS = os.getenv('HOSTADDRESS', HOSTALIAS)
SERVICESTATE = os.getenv('SERVICESTATE', 'none')
LONGDATETIME = os.getenv('LONGDATETIME', 'none')
SERVICEOUTPUT = os.getenv('SERVICEOUTPUT', 'none')
NOTIFICATIONAUTHORNAME = os.getenv('NOTIFICATIONAUTHORNAME', 'none')
NOTIFICATIONCOMMENT = os.getenv('NOTIFICATIONCOMMENT', 'none')
HOSTDISPLAYNAME = os.getenv('HOSTDISPLAYNAME', 'none')
SERVICEDISPLAYNAME = os.getenv('SERVICEDISPLAYNAME', 'none')
USEREMAIL = os.getenv('USEREMAIL', 'none')
SERVICEPERFDATA = os.getenv('SERVICEPERFDATA') # needs to be null to avoid it
HOSTURL = os.getenv('HOSTURL', 'none')
SERVICEURL = os.getenv('SERVICEURL', SERVICEDESC)
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
if not SERVICEURL:
  SERVICEURL = SERVICEDESC

SUBJECTMESSAGE = NOTIFICATIONTYPE + ' - ' + HOSTDISPLAYNAME + ' - ' + SERVICEDISPLAYNAME + ' is ' + SERVICESTATE

if PANELURL:
  GRAFANAPNG = GRAFANABASE + '/render/d-solo/' + GRAFANADASHBOARDUID + '/' + GRAFANADASHBOARD + '?&panelId=' + PANELURL + '&' + GRAFANAVARHOST + '=' + HOSTURL + '&' + GRAFANAVARSERVICE + '=' + SERVICEURL + '&' + GRAFANAVARCOMMAND + '=' + CHECKCOMMAND + '&theme=' + GRAFANATHEME + '&width=' + WIDTH + '&height=' + HEIGHT
  GRAFANALINK = GRAFANABASE + '/d/' + GRAFANADASHBOARDUID + '/' + GRAFANADASHBOARD + '?&panelId=' + PANELURL + '&' + GRAFANAVARHOST + '=' + HOSTURL + '&' + GRAFANAVARSERVICE + '=' + SERVICEURL + '&' + GRAFANAVARCOMMAND + '=' + CHECKCOMMAND

TEXT = '***** Icinga  *****'
TEXT += '\n'
TEXT += '\nNotification Type: ' + NOTIFICATIONTYPE
TEXT += '\n'
TEXT += '\nService: ' + SERVICEDESC
TEXT += '\nHost: ' + HOSTALIAS
TEXT += '\nAddress: ' + HOSTADDRESS
TEXT += '\nState: ' + SERVICESTATE
TEXT += '\n'
TEXT += '\nDate/Time: ' + LONGDATETIME
TEXT += '\n'
TEXT += '\nAdditional Info: ' + SERVICEOUTPUT
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
HTML += '\ntd.OK {background-color: #44bb77; color: #ffffff; margin-left: 2px;}'
HTML += '\ntd.WARNING {background-color: #ffaa44; color: #ffffff; margin-left: 2px;}'
HTML += '\ntd.CRITICAL {background-color: #ff5566; color: #ffffff; margin-left: 2px;}'
HTML += '\ntd.UNKNOWN {background-color: #aa44ff; color: #ffffff; margin-left: 2px;}'
HTML += '\n</style></head><body>'
HTML += '\n<table width=' + WIDTH + '>'

if os.path.exists(logoImagePath):
  HTML += '\n<tr><th colspan=2 class=icinga width=' + WIDTH +'><img src="cid:icinga2_logo"></th></tr>'

HTML += '\n<tr><th width=' + COLUMN + '>Notification Type:</th><td class=' + SERVICESTATE + '>' + NOTIFICATIONTYPE + '</td></tr>'
HTML += '\n<tr><th>Service Name:</th><td>' + SERVICEDISPLAYNAME+ '</td></tr>'
HTML += '\n<tr><th>Service Status:</th><td>' + SERVICESTATE + '</td></tr>'
HTML += '\n<tr><th>Service Data:</th><td><a style="color: #0095bf; text-decoration: none;" href="' + ICINGA2BASE + '/monitoring/service/show?host=' + HOSTALIAS + '&service=' + SERVICEDESC + '">' + SERVICEOUTPUT.replace("\n", "<br>") + '</a></td></tr>'
HTML += '\n<tr><th>Hostalias:</th><td><a style="color: #0095bf; text-decoration: none;" href="' + ICINGA2BASE +'/monitoring/host/show?host=' + HOSTALIAS + '">' + HOSTALIAS + '</a></td></tr>'
HTML += '\n<tr><th>IP Address:</th><td>' + HOSTADDRESS + '</td></tr>'
HTML += '\n<tr><th>Event Time:</th><td>' + LONGDATETIME + '</td></tr>'

if (NOTIFICATIONAUTHORNAME and NOTIFICATIONCOMMENT):
  HTML += '\n<tr><th>Comment:</th><td>' + NOTIFICATIONCOMMENT + ' (' + NOTIFICATIONAUTHORNAME + ')</td></tr>'

if (SERVICEPERFDATA or PANELURL):
  HTML += '\n</table><br>'
  HTML += '\n<table width=' + WIDTH + '>'
  HTML += '\n<tr><th colspan=6 class=perfdata>Performance Data</th></tr>'
  if (SERVICEPERFDATA):
    HTML += '\n<tr><th>Label</th><th>Last Value</th><th>Warning</th><th>Critical</th><th>Min</th><th>Max</th></tr>'
    PERFDATALIST = SERVICEPERFDATA.split(" ")
    for PERFDATA in PERFDATALIST:
      if '=' not in PERFDATA:
        continue

      (LABEL,DATA) = PERFDATA.split("=")
      if (len(DATA.split(";")) is 5):
        (VALUE,WARNING,CRITICAL,MIN,MAX) = DATA.split(";")
#      else:
#        (VALUE,WARNING,CRITICAL,MIN) = DATA.split(";")
#        MAX = ''
      if (len(DATA.split(";")) is 4):
        (VALUE,WARNING,CRITICAL,MIN) = DATA.split(";")
        MAX = ''
      if (len(DATA.split(";")) is 3):
        (VALUE,WARNING,CRITICAL) = DATA.split(";")
        MAX = ''
        MIN = ''
      if (len(DATA.split(";")) is 2):
        (VALUE,WARNING) = DATA.split(";")
        MAX = ''
        MIN = ''
        CRITICAL = ''
      if (len(DATA.split(";")) is 1):
        VALUE = DATA
        MAX = ''
        MIN = ''
        CRITICAL = ''
        WARNING = ''
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
