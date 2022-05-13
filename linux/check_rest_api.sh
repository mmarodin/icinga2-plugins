#!/bin/sh
#--------
# Check REST API script for Icinga2
# Require: curl, jq, RHEL 7.x compatible systems
# v.20201019 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":H:m:u:k:c:w:h" optname ; do
    case "$optname" in
      "H")
        HOST=$OPTARG
        ;;
      "w")
        WARN=$OPTARG
        ;;
      "c")
        CRIT=$OPTARG
        ;;
      "h")
        echo "Useage: check_rest_api.sh -H url -u username:password -k key -c critical -w warning [-m method]"
        exit 2
        ;;
      "H")
        HOST=$OPTARG
        ;;
      "u")
        CREDENTIALS=$OPTARG
        ;;
      "m")
        METHOD=$OPTARG
        ;;
      "k")
        KEY=$OPTARG
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

  [ -z $HOST ] && echo "Please specify URL!" && exit 2
  [ -z $CREDENTIALS ] && echo "Please specify username:password!" && exit 2
  [ -z $KEY ] && echo "Please specify searched key!" && exit 2
  [ -z $WARN ] && echo "Please specify warning value!" && exit 2
  [ -z $CRIT ] && echo "Please specify critical value!" && exit 2
  [ -z $METHODE ] && METHODE="GET"

OUTPUT=`curl -s "$HOST" --basic -u $CREDENTIALS -X $METHODE`
RES=$?
  if [ "$RES" != "0" ] ; then
    echo "Execution problem, something went wrong!"
   exit 2
  fi
VALUE=`echo $OUTPUT | jq -r $KEY`
RES=$?
  if [ "$RES" != "0" ] ; then
    echo "Execution problem, something went wrong!"
   exit 2
  fi

#"errorMessage" : "No JDBj Pooled Database Connections."
  [ "$VALUE" == "null" ] && VALUE=0

VALUENAME=`echo "$KEY" | sed 's/.*\.//'`

echo -n "Key: $VALUENAME $VALUE - "

  if [ $VALUE -gt $CRIT ] ; then
    EXIT=2
    STATUS="CRITICAL"
  elif [ $VALUE -gt $WARN ] ; then
    EXIT=1
    STATUS="WARNING"
  else
    STATUS="OK"
  fi
   
echo "$STATUS | '$VALUENAME'="$VALUE";;;"
exit $EXIT
