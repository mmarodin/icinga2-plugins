#!/bin/sh
#--------
# Check interface traffic script for Icinga2
# Require: bc, net-tools, RHEL 7.x compatible systems
# v.20160310 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":i:c:w:h" optname ; do
    case "$optname" in
      "i")
        INT=$OPTARG
        ;;
      "c")
        CRIT=$OPTARG
        ;;
      "w")
        WARN=$OPTARG
        ;;
      "h")
        echo "Useage: check_traffic.sh -i interface -w warn -c crit"
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

  [ -z $INT ] && echo "Please input device!" && exit 2
/sbin/ifconfig $INT >/dev/null 2>&1
  [ $? -ne 0 ] && echo "error: no device $INT" && exit 2 || DEVICE=$INT

  [ -z $WARN ] && WARN=1048576
  [ -z $CRIT ] && CRIT=2097152

DIR=/tmp
FILE=$DIR/tmp_icinga2_int.$DEVICE
  [ -e $FILE ] || > $FILE
chown icinga:icinga $FILE
  if [ `cat $FILE | wc -c` -eq 0 ] ; then
    echo -en `date +%s`"\t" >$FILE
    echo -en `/sbin/ifconfig $DEVICE | grep "RX packets" | awk '{print $5}'`"\t" >>$FILE
    echo `/sbin/ifconfig $DEVICE | grep "TX packets" | awk '{print $5}'`>>$FILE
    echo "This is first run"
  else
    New_Time=`date +%s`
    New_In=`/sbin/ifconfig $DEVICE | grep "RX packets" | awk '{print $5}'`
    New_Out=`/sbin/ifconfig $DEVICE | grep "TX packets" | awk '{print $5}'`
    Old_Time=`cat $FILE | awk '{print $1}'`
    Old_In=`cat $FILE | awk '{print $2}'`
    Old_Out=`cat $FILE | awk '{print $3}'`

    Diff_Time=`echo "$New_Time-$Old_Time" | bc`
      [ $Diff_Time -le 5 ] && echo "less 5s" && exit 1
    Diff_In=`echo "scale=0;($New_In-$Old_In)*8/$Diff_Time" | bc`
    Diff_Out=`echo "scale=0;($New_Out-$Old_Out)*8/$Diff_Time" | bc`
      [ $Diff_In -le 0 ] && Diff_In=`cat $FILE | awk '{print $4}'`
      [ $Diff_Out -le 0 ] && Diff_Out=`cat $FILE | awk '{print $5}'`
    echo "$New_Time $New_In $New_Out $Diff_In $Diff_Out" >$FILE

      if [ $Diff_In -gt $CRIT -o $Diff_In -eq $CRIT ];then
        echo -e "$DEVICE:CRIT (in=`echo "$Diff_In/1024" | bc`Kbps/out=`echo "$Diff_Out/1024" | bc`Kbps)|'${DEVICE}_in_bps'=${Diff_In};${WARN};${CRIT};0;0 '${DEVICE}_out_bps'=${Diff_Out};${WARN};${CRIT};0;0"
        exit 2
      fi
      if [ $Diff_In -gt $WARN -o $Diff_In -eq $WARN ];then
        echo -e "$DEVICE:WARN (in=`echo "$Diff_In/1024" | bc`Kbps/out=`echo "$Diff_Out/1024" | bc`Kbps)|'${DEVICE}_in_bps'=${Diff_In};${WARN};${CRIT};0;0 '${DEVICE}_out_bps'=${Diff_Out};${WARN};${CRIT};0;0"
        exit 1
      fi
      if [ $Diff_In -lt $WARN ];then
        echo -e "$DEVICE:OK (in=`echo "$Diff_In/1024" | bc`Kbps/out=`echo "$Diff_Out/1024" | bc`Kbps)|'${DEVICE}_in_bps'=${Diff_In};${WARN};${CRIT};0;0 '${DEVICE}_out_bps'=${Diff_Out};${WARN};${CRIT};0;0"
        exit 0
      fi

  fi
