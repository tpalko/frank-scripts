#!/bin/bash 

SLEEP_DEFAULT=1
SLEEP=$1
SLEEP=${SLEEP:=${SLEEP_DEFAULT}}

function randhex() {
  printf "%x" $(( RANDOM % 2 * 15 ))
}

function randrgb() {
 RED=$(randhex)
 GREEN=$(randhex)
 BLUE=$(randhex)
 printf "${RED}${RED}${GREEN}${GREEN}${BLUE}${BLUE}"
}

BLACK=000000
#PREVCOLOR=${BLACK}

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
  openrgb --noautoconnect -m static -d 0 -z 0 -c ${CASE_FAN},${CASE_FAN},${CASE_FAN},${CASE_FAN},${CASE_FAN},${CASE_FAN},${CASE_FAN},${CASE_FAN},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CPU_FAN} > /dev/null
  #echo ${COLOR} > ~/.moborgb
  [[ ${SLEEP} -gt -1 ]] && sleep ${SLEEP} || break 
done 
