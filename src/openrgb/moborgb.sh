#!/bin/bash 

SLEEP_DEFAULT=1
SLEEP=$1
SLEEP=${SLEEP:=${SLEEP_DEFAULT}}

# print either 0 or f 
function randhex() {
  printf "%x" $(( RANDOM % 2 * 15 ))
}

# print 000000 -> ffffff in increments of f 
function randrgb() {
  # RED=ff0000
  # ORANGE=ff8000
  # YELLOW=ffff00
  # CHART=80ff00
  # GREEN=00ff00
  # SPGREEN=00ff80
  # CYAN=00ffff
  # DBLUE=0080ff
  # BLUE=0000ff
  # PURPLE=8000ff
  # VIOLET=ff00ff
  # MAGENTA=ff0080
  RED=$(randhex)
  GREEN=$(randhex)
  BLUE=$(randhex)
  printf "${RED}${RED}${GREEN}${GREEN}${BLUE}${BLUE}"
}

BLACK=000000
#PREVCOLOR=${BLACK}

# cycles colors every SLEEP seconds 
while :; do
  CASE_FAN=${BLACK}
  CASE_FAN_RING=${BLACK}
  CPU_FAN=${BLACK}
  #[[ -f ~/.moborgb ]] && PREVCOLOR=$(cat ~/.moborgb)
  while [[ "${CASE_FAN}" = "${CASE_FAN_RING}" || "${CASE_FAN}" = "${CPU_FAN}" ]]; do 
    CASE_FAN=$(randrgb)
    CASE_FAN_RING=$(randrgb)
    CPU_FAN=$(randrgb)
  done 
  # every setup is different
  # this one is 3 coolermaster case fans linked together + cpu fan 
  # the case fans are not independently addressable
  # 8 codes for the case fan blades 
  # 16 codes for the case fan rings 
  # 1 code for the cpu fan 
  openrgb --noautoconnect -m static -d 0 -z 0 -c ${CASE_FAN},${CASE_FAN},${CASE_FAN},${CASE_FAN},${CASE_FAN},${CASE_FAN},${CASE_FAN},${CASE_FAN},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CPU_FAN} > /dev/null
  #echo ${COLOR} > ~/.moborgb
  [[ ${SLEEP} -gt -1 ]] && sleep ${SLEEP} || break 
done 
