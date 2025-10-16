#!/bin/bash 

DEFAULT_DEVICE=${COWIN_ID}
DEVICE=${DEFAULT_DEVICE}

function set_device() {
  printf "Device is ${DEVICE}\n"
}

function menu() {

  printf "\tset device\n"
  printf "\tshow\n"
  printf "\tdevices\n"
  printf "\tpower\n"
  printf "\tdiscoverable\n"
  printf "\tscan\n"
  printf "\tinfo DEVICE\n"
  printf "\tpair/cancel-pairing DEVICE\n"
  printf "\tremove DEVICE\n"
  printf "\ttrust/untrust DEVICE\n"
  printf "\tconnect/disconnect DEVICE\n"
  printf "? "

  read OPT

  case ${OPT} in
    dev)	OPT=devices
		;;
    disc)	OPT=discoverable
		;;
    conn)	OPT=connect
		;;
  esac 

  case ${OPT} in 
    set)						set_device
							;;
    show|devices)					bluetoothctl ${OPT}
							;;
    power|discoverable|scan)				bluetoothctl ${OPT} on
							;;
    info|remove|pair|cancel-pairing|trust|untrust|connect|disconnect)		bluetoothctl ${OPT} ${DEVICE}
							;;
  esac
  printf ".."
  read
} 

while :; do menu; done 

