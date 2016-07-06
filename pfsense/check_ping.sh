#!/bin/sh
#--------
# Check pfSense ping from source script for Icinga2
# v.20160620 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":s:d:w:r:R:k:K:h" optname ; do
    case "$optname" in
      "s")
        INTERFACE=$OPTARG
        ;;
      "d")
        DESTINATION=$OPTARG
        ;;
      "r")
        WRTA=$OPTARG
        ;;
      "R")
        CRTA=$OPTARG
        ;;
      "k")
        WPL=$OPTARG
        ;;
      "K")
        CPL=$OPTARG
        ;;
      "h")
        echo "Useage: check_ping.sh -s source_interface -d destination_address -r warning_rta -R critical_rta -k warning_pl -K critical_pl"
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

  [ -z $INTERFACE ] && echo "Please specify source interface!" && exit 2

COUNT=5
TIMEOUT=10
IFS_CURRENT=$IFS
IFS_NL='
'

  [ -z $WRTA ] && WRTA=100
  [ -z $CRTA ] && CRTA=200
  [ -z $WPL ] && WPL=5
  [ -z $CPL ] && CPL=15

SOURCE=`ifconfig $INTERFACE | grep "inet " -m 1 | awk '{print $2'}`

  if [ -z $DESTINATION ] ; then
    case "$INTERFACE" in
      *vpn*)
        DESTINATION=`ifconfig $INTERFACE | grep "inet " -m 1 | awk '{print $4'}`
        ;;
      *)
        DESTINATION="8.8.8.8"
        ;;
    esac
  fi

IFS=$IFS_NL
  for ROW in `ping -S $SOURCE -c $COUNT -t $TIMEOUT $DESTINATION` ; do
    case "$ROW" in
      *packet\ loss*)
        PL=`echo $ROW | awk '{print $7}' | awk 'BEGIN { FS = "%"} { print $1}'`
        ;;
      *round-trip*)
        RTA=`echo $ROW | awk 'BEGIN { FS = "/" } { print $5 }'`
        ;;
      *)
        ;;
    esac
  done
IFS=$IFS_CURRENT

echo -n "PING "
  if [ "`echo "$PL > $CPL" | bc`" == "1" ] ; then
    echo -n "CRITICAL"
    EXIT=2
  elif [ "`echo "$PL > $WPL" | bc`" == "1" ] ; then
    echo -n "WARNING"
    EXIT=1
  elif [ $RTA ] ; then
      if [ "`echo "$RTA > $CRTA" | bc`" == "1" ] ; then
	echo -n "CRITICAL"
	EXIT=2
      elif [ "`echo "$RTA > $WRTA" | bc`" == "1" ] ; then
	echo -n "WARNING"
	EXIT=1
      else
	echo -n "OK"
	EXIT=0
      fi
  else
    echo -n "KO"
    EXIT=2
  fi
echo -n " from $INTERFACE (src $SOURCE, dst $DESTINATION) - Packet loss = $PL%"
  [ $RTA ] && echo -n ", RTA = $RTA ms" || RTA=$CRTA
echo " | 'rta'="$RTA"ms;$WRTA;$CRTA;0 'pl'=$PL%;$WPL;$CPL;0"
exit $EXIT
