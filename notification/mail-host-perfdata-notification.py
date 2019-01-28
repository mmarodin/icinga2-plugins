#!/bin/python
#------------
# Host notification script for Icinga 2
# Customized for Icinga 2 v2.10.2, InfluxDB 1.7.2 and Grafana 5.4.2
# v.20190114 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#
import argparse
import os
import smtplib
import socket
import urllib
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
GRAFANAORGID = 'yourorgid'
GRAFANADASHBOARDUID = 'yourdashboarduid'
GRAFANAVARHOST = 'var-hostname'
GRAFANATHEME = 'light'
GRAFANAAPIKEY = 'yourAPIkey'
WIDTH = '640'
HEIGHT = '321'
COLUMN = '144'
DIFFERENCE = str(int(WIDTH) - int(COLUMN))

# Icinga 2 >= 2.7.x uses command line parameters instead of environment variables
text = 'Host notification script for Icinga 2'
parser = argparse.ArgumentParser()
parser = argparse.ArgumentParser(description = text)
parser.add_argument("--longdatetime", "-d", help="set icinga.long_date_time")
parser.add_argument("--hostname", "-l", help="set host.name")
parser.add_argument("--hostdisplayname", "-n", help="set host.display_name")
parser.add_argument("--hostoutput", "-o", help="set host.output")
parser.add_argument("--useremail", "-r", help="set user.email")
parser.add_argument("--hoststate", "-s", help="set host.state")
parser.add_argument("--notificationtype", "-t", help="set notification.type")
parser.add_argument("--hostaddress", "-4", help="set address")
parser.add_argument("--hostaddress6", "-6", help="set address6")
parser.add_argument("--notificationauthorname", "-b", help="set notification.author")
parser.add_argument("--notificationcomment", "-c", help="set notification.comment")
parser.add_argument("--icingaweb2url", "-i", help="set notification_icingaweb2url")
parser.add_argument("--mailfrom", "-f", help="set notification_mailfrom")
parser.add_argument("--verbose", "-v", help="set notification_sendtosyslog")
parser.add_argument("--hostperfdata", "-p", help="set host.perfdata")
parser.add_argument("--panelid", "-a", help="set host.vars.panel_id")
args = parser.parse_args()

if not all ([args.longdatetime, args.hostname, args.hostdisplayname, args.hostoutput, args.useremail, args.hoststate, args.notificationtype]):
  print("Missing required parameters!")
  os.sys.exit(2)

DEBUG = args.verbose

TO = args.useremail
#TO = 'root@icinga2.fqdn.here'

# Logo for Icinga 2 <= 2.5.x
#logoImagePath = '/usr/share/icingaweb2/public/img/logo_icinga-inv.png'
# Logo for Icinga 2 >= 2.6.x
logoImagePath = '/usr/share/icingaweb2/public/img/icinga-logo.png'

if not args.hostaddress:
  args.hostaddress = args.hostname

SUBJECTMESSAGE = args.notificationtype + ' - ' + args.hostdisplayname + ' is ' + args.hoststate

if args.panelid:
  GRAFANAURL = GRAFANABASE + '/render/d-solo/' + GRAFANADASHBOARDUID + '/' + GRAFANADASHBOARD
  GRAFANAVLS = {GRAFANAVARHOST : args.hostname,
		'orgId' : GRAFANAORGID,
		'panelId' : args.panelid,
		'theme' : GRAFANATHEME,
		'width' : WIDTH,
		'height' : HEIGHT}
  GRAFANAPNG = GRAFANAURL + '?' + urllib.urlencode(GRAFANAVLS)
  GRAFANALINK = GRAFANABASE + '/d/' + GRAFANADASHBOARDUID + '/' + GRAFANADASHBOARD + '?' + GRAFANAVARHOST + '=' + args.hostname + '&orgId=' + GRAFANAORGID + '&panelId=' + args.panelid + '&fullscreen&refresh=30s'

# Prepare mail body
TEXT = '***** Icinga  *****'
TEXT += '\n'
TEXT += '\nNotification Type: ' + args.notificationtype
TEXT += '\n'
TEXT += '\nHost: ' + args.hostname
TEXT += '\nAddress: ' + args.hostaddress
TEXT += '\nState: ' + args.hoststate
TEXT += '\n'
TEXT += '\nDate/Time: ' + args.longdatetime
TEXT += '\n'
TEXT += '\nAdditional Info: ' + args.hostoutput
TEXT += '\n'
TEXT += '\nComment: [' + args.notificationauthorname + '] ' + args.notificationcomment

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

HTML += '\n<tr><th width=' + COLUMN + '>Notification Type:</th><td class=' + args.hoststate + '>' + args.notificationtype + '</td></tr>'
HTML += '\n<tr><th>Hostalias:</th><td><a style="color: #0095bf; text-decoration: none;" href="' + ICINGA2BASE +'/monitoring/host/show?host=' + args.hostname + '">' + args.hostname + '</a></td></tr>'
HTML += '\n<tr><th>IP Address:</th><td>' + args.hostaddress + '</td></tr>'
HTML += '\n<tr><th>Host Status:</th><td>' + args.hoststate + '</td></tr>'
HTML += '\n<tr><th>Service Name:</th><td>ping4</td></tr>'
HTML += '\n<tr><th>Service Data:</th><td><a style="color: #0095bf; text-decoration: none;" href="' + ICINGA2BASE + '/monitoring/host/services?host=' + args.hostname + '">' + args.hostoutput + '</a></td></tr>'
HTML += '\n<tr><th>Event Time:</th><td>' + args.longdatetime + '</td></tr>'

if (args.notificationauthorname and args.notificationcomment):
  HTML += '\n<tr><th>Comment:</th><td>' + args.notificationcomment + ' (' + args.notificationauthorname + ')</td></tr>'

if (args.hostperfdata or args.panelid):
  HTML += '\n</table><br>'
  HTML += '\n<table width=' + WIDTH + '>'
  HTML += '\n<tr><th colspan=6 class=perfdata>Performance Data</th></tr>'
  if (args.hostperfdata):
    HTML += '\n<tr><th>Label</th><th>Last Value</th><th>Warning</th><th>Critical</th><th>Min</th><th>Max</th></tr>'
    PERFDATALIST = args.hostperfdata.split(" ")
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

if args.panelid:
  HTML += '\n<tr><td colspan=6><a href="' + GRAFANALINK + '"><img src="cid:grafana_perfdata" width=' + WIDTH + ' height=' + HEIGHT + '></a></td></tr>'

HTML += '\n</table><br>'
HTML += '\n<table width=' + WIDTH + '>'
HTML += '\n<tr><td class=center>Generated by Icinga 2 and Grafana</td></tr>'
HTML += '\n</table><br>'
HTML += '\n</body></html>'

if DEBUG == 'true':
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

if args.panelid:
  GET = urllib2.Request(GRAFANAPNG)
  GET.add_header('Authorization','Bearer ' + GRAFANAAPIKEY)
  GRAPH = urllib2.urlopen(GET)
  PNG = GRAPH.read()
  msgImage = MIMEImage(PNG)
  msgImage.add_header('Content-ID', '<grafana_perfdata>')
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
