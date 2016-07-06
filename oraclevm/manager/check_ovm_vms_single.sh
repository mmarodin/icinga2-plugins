#!/bin/sh
#--------
# Check Oracle VM single istances of VMs script for Icinga2
# v.20160509 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":h" optname ; do
    case "$optname" in
      "h")
        echo "Useage: check_ovm_vms_single.sh -H hostname -C checkname [-p parameters]"
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

HV_LIST=(srv01 srv02 srv03)
COUNT=0

  for HYPERVISOR in ${HV_LIST[@]}; do
    VM_LIST[$COUNT]=`ssh $HYPERVISOR xm list | grep -v Name | grep -v Domain-0 | awk '{print $1}'`
    COUNT=`echo "$COUNT + 1" | bc`
  done

VM_COUNT=`echo ${VM_LIST[*]} | tr ' ' '\n' | wc -l`
VM_DUPLICATE=`echo ${VM_LIST[*]} | tr ' ' '\n' | sort | uniq -d`

  if [ "$VM_DUPLICATE" ] ; then
    echo -n "CRITICAL: Duplicate running VM found ("
    CHECK=0
      for VM_UID in `echo $VM_DUPLICATE`; do
	  [ $CHECK == 1 ] && echo -n "; " && CHECK=0
	echo -n "$VM_UID: "
	COUNT=0
	  for HYPERVISOR in ${HV_LIST[@]}; do
	      if [ "`echo ${VM_LIST[$COUNT]} | grep $VM_UID`" ]; then
		  [ $CHECK == 1 ] && echo -n ", "
		echo -n $HYPERVISOR
		CHECK=1
	      fi
	    COUNT=`echo "$COUNT + 1" | bc`
	  done
      done
    echo -n ")"
    EXIT=2
  else
    echo -n "OK: Total running VMs $VM_COUNT"
    EXIT=0
  fi

echo " | 'vms'=$VM_COUNT;;;"
exit $EXIT
