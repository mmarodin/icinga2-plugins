#!/bin/sh
#--------
# Check Hypervisor memory script for Icinga2
# Customized for Oracle VM server 3.2
# v.20160509 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

alias bc='/opt/scripts/icinga2/bc'

  while getopts ":w:c:h" optname ; do
    case "$optname" in
      "w")
        WARN=$OPTARG
        ;;
      "c")
        CRIT=$OPTARG
        ;;
      "h")
        echo "Useage: check_ovm_mem.sh -w warning -c critical"
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

  [ -z $WARN ] && WARN=85
  [ -z $CRIT ] && CRIT=95

MEMORY=(`xm info | grep _memory | awk '{print $3}'`)
  [ ${#MEMORY[@]} != 2 ] && echo "Something went wrong!" && exit 2

MEM_TOTAL=`echo "${MEMORY[0]} * 1024" | bc`
MEM_FREE=`echo "${MEMORY[1]} * 1024" | bc`
MEM_USED=`echo "$MEM_TOTAL - $MEM_FREE" | bc`

MEM_CRIT=`echo "scale=0;$(expr $MEM_TOTAL / 100) * $CRIT" | bc`
MEM_WARN=`echo "scale=0;$(expr $MEM_TOTAL / 100) * $WARN" | bc`
USAGE=`echo "scale=2 ; $MEM_USED / $MEM_TOTAL * 100" | bc`

echo -n "RAM:$USAGE% - "
  if [ $MEM_USED -ge $MEM_CRIT ] ; then
    echo -n "CRITICAL"
    EXIT=1
  elif [ $MEM_USED -ge $MEM_WARN ] ; then
    echo -n "WARNING"
    EXIT=2
  else
    echo -n "OK"
    EXIT=0
  fi
echo " | 'ram_used'="$MEM_USED"KB;"$MEM_WARN";"$MEM_CRIT";0;"$MEM_TOTAL
exit $EXIT
