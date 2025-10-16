#!/bin/bash 

SLEEP_DEFAULT=1
SLEEP=$1
SLEEP=${SLEEP:=${SLEEP_DEFAULT}}

# print either 0 or f 
function randhex() {
  printf "%x" $(( RANDOM % 16 ))
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
  # RED=$(randhex)
  # GREEN=$(randhex)
  # BLUE=$(randhex)
  # printf "${RED}${RED}${GREEN}${GREEN}${BLUE}${BLUE}"
  printf "$(randhex)$(randhex)$(randhex)$(randhex)$(randhex)$(randhex)"
}

BLACK=000000
#PREVCOLOR=${BLACK}

# cycles colors every SLEEP seconds 
while :; do
  CASE_FAN=${BLACK}
  CASE_FAN_RING=${BLACK}
  CPU_FAN=${BLACK}
  #[[ -f ~/.moborgb ]] && PREVCOLOR=$(cat ~/.moborgb)
  while [[ "${CASE_FAN}" = "${CASE_FAN_RING}" || "${CASE_FAN}" = "${CPU_FAN}" || ${CPU_FAN} = ${BLACK} ]]; do 
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
  
  OPTS="--noautoconnect -m direct" # -d 0 -z 0"
  
  SET_1=${CASE_FAN},${CASE_FAN},${CASE_FAN},${CASE_FAN},${CASE_FAN},${CASE_FAN},${CASE_FAN},${CASE_FAN}

  SET_2=${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING},${CASE_FAN_RING}

  SET_3=${CPU_FAN},${CPU_FAN} #,${CPU_FAN},${CPU_FAN},${CPU_FAN},${CPU_FAN},${CPU_FAN},${CPU_FAN}

  echo "Case: ${CASE_FAN}"
  echo "Ring: ${CASE_FAN_RING}"
  echo "CPU: ${CPU_FAN}"

  openrgb ${OPTS} -c ${SET_1},${SET_2},${SET_3} # > /dev/null 
  
  #DEV_N_ZONE="-d 0 -z 1"

  #openrgb --noautoconnect -m static ${DEV_N_ZONE} -c ${CPU_FAN},${CPU_FAN},${CPU_FAN},${CPU_FAN},${CPU_FAN},${CPU_FAN},${CPU_FAN},${CPU_FAN} > /dev/null

  #DEV_N_ZONE="-d 0 -z 2"

  #openrgb --noautoconnect -m static ${DEV_N_ZONE} -c ${CPU_FAN},${CPU_FAN},${CPU_FAN},${CPU_FAN},${CPU_FAN},${CPU_FAN},${CPU_FAN},${CPU_FAN} > /dev/null

  #echo ${COLOR} > ~/.moborgb
  [[ ${SLEEP} -gt -1 ]] && sleep ${SLEEP} || break 
done 



# 'Name for LED Strip 1 LED 0' 
# 'Name for LED Strip 1 LED 1' 
# 'Name for LED Strip 1 LED 2' 
# 'Name for LED Strip 1 LED 3' 
# 'Name for LED Strip 1 LED 4' 
# 'Name for LED Strip 1 LED 5' 
# 'Name for LED Strip 1 LED 6' 
# 'Name for LED Strip 1 LED 7' 
# 'Name for LED Strip 1 LED 8' 
# 'Name for LED Strip 1 LED 9' 
# 'Name for LED Strip 1 LED 10' 
# 'Name for LED Strip 1 LED 11' 
# 'Name for LED Strip 1 LED 12' 
# 'Name for LED Strip 1 LED 13' 
# 'Name for LED Strip 1 LED 14' 
# 'Name for LED Strip 1 LED 15' 
# 'Name for LED Strip 1 LED 16' 
# 'Name for LED Strip 1 LED 17' 
# 'Name for LED Strip 1 LED 18' 
# 'Name for LED Strip 1 LED 19' 
# 'Name for LED Strip 1 LED 20' 
# 'Name for LED Strip 1 LED 21' 
# 'Name for LED Strip 1 LED 22' 
# 'Name for LED Strip 1 LED 23' 
# 'Name for LED Strip 1 LED 24' 
# 'Name for LED Strip 1 LED 25' 
# 'Name for LED Strip 1 LED 26' 
# 'Name for LED Strip 1 LED 27' 
# 'Name for LED Strip 1 LED 28' 
# 'Name for LED Strip 1 LED 29' 
# 'Name for LED Strip 1 LED 30' 
# 'Name for LED Strip 1 LED 31' 
# 'Name for LED Strip 1 LED 32' 
# 'Name for LED Strip 1 LED 33' 
# 'Name for LED Strip 1 LED 34' 
# 'Name for LED Strip 1 LED 35' 
# 'Name for LED Strip 2 LED 0' 
# 'Name for LED Strip 2 LED 1' 
# 'Name for LED Strip 2 LED 2' 
# 'Name for LED Strip 2 LED 3' 
# 'Name for LED Strip 2 LED 4' 
# 'Name for LED Strip 2 LED 5' 
# 'Name for LED Strip 2 LED 6' 
# 'Name for LED Strip 2 LED 7' 
# 'Name for LED Strip 2 LED 8' 
# 'Name for LED Strip 2 LED 9' 
# 'Name for LED Strip 2 LED 10' 
# 'Name for LED Strip 2 LED 11' 
# 'Name for Led 1' 
# 'Name for Led 2' 
# 'Name for Led 3' 
# 'Name for Led 4' 
# 'Name for Led 5' 
# 'Name for Led 6' 
# 'Name for Led 7' 
# 'Name for Led 8'