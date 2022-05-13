#!/bin/bash
#----------
# Check ftp ssl expiration script for Icinga2
# v.20200615 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

 while getopts ":u:p:w:c:h" optname ; do
    case "$optname" in
      "u")
        URL=$OPTARG
        ;;
      "p")
        PORT=$OPTARG
        ;;
      "c")
        CRIT=$OPTARG
        ;;
      "w")
        WARN=$OPTARG
        ;;
      "h")
        echo "Useage: check_ftp_ssl_expiration.sh -u URL -p port -w warn -c crit"
        exit 2
        ;;
      "?")
        echo "Unknown option $OPTARG"
        exit 2
        ;;
      ":")
        echo "No argument value for option $OPTARG"
        exit 2
        ;;
      *)
      # Should not occur
        echo "Unknown error while processing options"
        exit 1
        ;;
    esac
  done

  [ -z $URL ] && echo "Please specify URL!" && exit 2
  [ -z $PORT ] && PORT="990"
  [ -z $WARN ] && WARN="30"
  [ -z $CRIT ] && CRIT="15"

DIR=/tmp
FILE=$DIR/tmp_icinga2_ftp.$URL

curl -v --ssl ftp://$URL:$PORT 2>$FILE

COMMON_NAME=`cat $FILE | grep "common name:" | sed 's/.*common name: \(.*\)/\1/g'`
SSL_DATE=`cat $FILE | grep "expire date:" | sed 's/.*expire date: \(.*\)/\1/g'`
EXP_DATE=`date -d"$SSL_DATE" +%s`
CUR_DATE=`date +%s`
DAYS=`echo "($EXP_DATE - $CUR_DATE) / (60*60*24)" | bc`

  if [ $DAYS -lt $CRIT ] ; then
    echo "CRITICAL - Certificate '$COMMON_NAME' expires in $DAYS day(s) ($SSL_DATE)"
    EXIT=2
  elif [ $DAYS -lt $WARN ] ; then
    echo "WARNING - Certificate '$COMMON_NAME' expires in $DAYS day(s) ($SSL_DATE)"
    EXIT=1
  else
    echo "OK - will expire on $SSL_DATE"
    EXIT=0
  fi

exit $EXIT
