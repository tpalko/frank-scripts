#!/bin/bash 

#   for MOUNT in /home /media/storage /var/lib/docker /media/orange-storange; do 
#     echo -n "${MOUNT}:$(df ${MOUNT} | grep -v Filesystem | awk '{ print $4"/"$5 }') "
#   done

# go check out https://www.weatherapi.com/
# and fix up .env.example -> .env 
export $(cat $(dirname $(readlink $0))/.env | xargs)
export PATH=${PATH}:/home/debian/tpalko/.asdf/bin:/home/debian/tpalko/.asdf/shims 
export ASDF_DIR=/home/debian/tpalko/.asdf

function get_minikube_status() {
  MINIKUBE_PATH=minikube # /home/debian/tpalko/.asdf/shims/minikube
  FULL_STATUS=$(${MINIKUBE_PATH} status 2>&1)
  MINIKUBE_STATUS=$(echo "${FULL_STATUS}" | grep -E "^host" | awk '{ print $2 }')
  printf "\n\n\
******************************************************** \n\n\
$(date +%Y-%m-%dT%H:%M:%S) \n\
path: ${PATH} \n\
env: $(env | sort) \n \
cluster: $(kubectl cluster-info) \n \
kubectl: $(kubectl version) \n \
docker: $(docker version) \n \
go: $(go env | sort) \n \
which minikube: $(which minikube) \n\
minikube path: ${MINIKUBE_PATH} \n\
${FULL_STATUS} \n\
****************************************************" >> ~/baraction-minikube-status.log
  echo "[minikube:${MINIKUBE_STATUS}]"
}

function get_raid_status() {
  if [[ -f ~/.bar-raidstatus ]]; then 
    STATUS=
    WROTE=0
    while read DEV; do 
      if [[ ${WROTE} -eq 1 ]]; then 
        STATUS="${STATUS}; "
      fi 
      STATUS="${STATUS}${DEV}"
      WROTE=1
    done < <(cat ~/.bar-raidstatus | jq -r ".devices | .[] | .device+\" \"+.status")    
    echo -n " [${STATUS}] "
  else 
    echo "no raid status"
  fi 
}

function set_raid_status() {

  LAST_UPDATED=-1 
  STATUS=
  if [[ -f ~/.bar-raidstatus ]]; then 
    LAST_UPDATED=$(cat ~/.bar-raidstatus | jq -r ".last_updated")
    STATUS=$(cat ~/.bar-raidstatus | jq -r ".status")
  fi 

  if [[ $? -ne 0 || -z "${STATUS}" || ${LAST_UPDATED} -eq -1 || $(( $(date +%s) - ${LAST_UPDATED} )) -gt 300 ]]; then 

    DEVICES=$(cat /proc/mdstat | grep -vE "^\s|^$|Personalities|unused devices" | awk '{ print $1 }')
    
    OUTFILE="{\"last_updated\":\"$(date +%s)\",\"devices\":["
    WROTE=0

    while read DEVICE; do 
      if [[ ${WROTE} -eq 1 ]]; then 
        OUTFILE="${OUTFILE},"
      fi 
      #RAID_STATUS=$(mdadm --detail /dev/md0 | grep -E "^\s+State" | awk '{ $1="";$2=""; print $0 }')
      DETAIL=$(sudo mdadm --detail /dev/${DEVICE})
      STATUS=$(echo "${DETAIL}" | grep -E "^\s+State" | awk '{ $1="";$2=""; print $0 }' | xargs)
      REBUILD_STATUS=$(echo "${DETAIL}" | grep -E "^\s+Rebuild|\s+Resync" | awk '{ print $4 }' | xargs)      
      OUTFILE="${OUTFILE}{\"device\":\"${DEVICE}\",\"status\":\"${STATUS}"
      if [[ -n "${REBUILD_STATUS}" ]]; then 
        OUTFILE="${OUTFILE} ${REBUILD_STATUS}"
      fi 
      OUTFILE="${OUTFILE}\"}"
      WROTE=1
    done < <(echo "${DEVICES}")

    OUTFILE="${OUTFILE}]}"

    echo ${OUTFILE} > ~/.bar-raidstatus
  fi 
}

function get_weather() {
  if [[ -f ~/.weather ]]; then 
    TEMPF="$(cat ~/.weather | jq -r '.current.temp_f')"
    COND=$(cat ~/.weather | jq -r ".current.condition.text")
    echo ${TEMPF}F/${COND}
  else 
    echo "no weather data"
  fi 
}

function set_weather() {
  LAST_UPDATED=901
  if [[ -f ~/.weather ]]; then 
    LAST_UPDATED=$(cat ~/.weather | jq -r ".current.last_updated_epoch")
  fi 
  # if last updated for whatever reason isn't recent, then update 
  if [[ $? -ne 0 || -z "${LAST_UPDATED}" || $(( $(date +%s) - ${LAST_UPDATED} )) -gt 900 ]]; then 
    curl -s --url "http://api.weatherapi.com/v1/current.json?key=${WEATHER_KEY}&q=${WEATHER_ZIP}&aqi=no" -o ~/.weather
  fi
}

function den2unit() {
  local DEN=$1
  case ${DEN} in 
    1) UNIT=B;;
    $(( 2 ** 10 )))  UNIT=K;;
    $(( 2 ** 20 )))  UNIT=M;;
    $(( 2 ** 30 )))  UNIT=G;;
    $(( 2 ** 40 )))  UNIT=T;;
    $(( 2 ** 50 )))  UNIT=P;;
    *)  UNIT=?;;
  esac
  echo ${UNIT}
}

function unit2den() {
  local UNIT=$1
  case ${UNIT} in
    B)  echo $(( 2 ** 0 ));;
    K)  echo $(( 2 ** 10 ));;
    M)  echo $(( 2 ** 20 ));;
    G)  echo $(( 2 ** 30 ));;
    T)  echo $(( 2 ** 40 ));;
    P)  echo $(( 2 ** 50 ));;
  esac 
}

function human() {
  
  SIZE=$1
  UNIT=$2
  
  # python -c "import sys; print(\"%.5f\" % (int(sys.argv[1])*1.0 / int(sys.argv[2])*1.0) )" <<< echo 243523 1223
  
  DEN=$(unit2den ${UNIT})
  # reset to Bytes 
  FREE=$(( ${SIZE} * ${DEN} ))
  # the DEN multiplier here is a threshold FREE must meet to jump to the next power of 2
  # with 1024 we're saying show at least a whole number (593G, not 0.58T)
  # with 10 we're saying if less than 10 of a unit
  # display thousands of a lesser unit (7235M, not 7G)
  # -- bytes must be > 10K to be shown in K
  # -- kilobytes must be > 10M to be shown in M
  while [[ ${FREE} -gt $(( ${DEN} * 1024 * 10 )) ]]; do 
    DEN=$(( ${DEN} * 1024 ))
  done 
  
  UNIT=$(den2unit ${DEN})
  
  echo $(( ${FREE} / ${DEN} ))${UNIT}  
}

function space() {
  
  DEVICE_PATH=$1
  
  TOTAL=$(df -k 2>/dev/null | grep ${DEVICE_PATH} | awk '{ print $2 }')
  USED=$(df -k 2>/dev/null | grep ${DEVICE_PATH} | awk '{ print $3 }')
  AVAIL=$(df -k 2>/dev/null | grep ${DEVICE_PATH} | awk '{ print $4 }')
  
  echo $(human $(( ${AVAIL} )) K)
}

while :; do

  set_weather
  set_raid_status
  
  # assuming vol is in use 
  # `vol get` will return a numeric level 
  # .customaudio will contain either "headphones" or "speakers"
  CUSTOMAUDIO=$(cat ~/.customaudio) 
  SOUND="vol:$(vol get)${CUSTOMAUDIO::1}"

  IPADDR=$([[ $(ip addr show ${INTERFACE} | grep inet) =~ ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) ]] && echo ${BASH_REMATCH[0]})  

  NETWORK="-"
  if [[ $(groups | grep wheel 2>&1 > /dev/null) -eq 0 ]]; then 
    IFTOP=$(sudo iftop -B -t -i ${INTERFACE} -s 1 2>/dev/null)
    SENDRATE=$(echo "${IFTOP}" | grep "Total send rate" | awk '{ print $6 }')
    RECEIVERATE=$(echo "${IFTOP}" | grep "Total receive rate" | awk '{ print $6 }')
    NETWORK="u${SENDRATE}/d${RECEIVERATE}"
  fi 
  # DISK_INFO=$(iostat -o JSON | jq -r ".sysstat.hosts | .[] | .statistics | .[] | .disk | .[]")
  # 
  # SD_INFO=$(echo "${DISK_INFO}" | jq -r "select(.disk_device | startswith(\"sd\"))")
  # SD_READ=$( human $(echo "${SD_INFO}" | jq -r ".kB_read" | paste -sd+ | bc) K)
  # SD_WRITE=$( human $(echo "${SD_INFO}" | jq -r ".kB_wrtn" | paste -sd+ | bc) K)
  # 
  # MD_INFO=$(echo "${DISK_INFO}" | jq -r "select(.disk_device | startswith(\"md\"))")
  # MD_READ=$( human $(echo "${MD_INFO}" | jq -r ".kB_read" | paste -sd+ | bc) K)
  # MD_WRITE=$( human $(echo "${MD_INFO}" | jq -r ".kB_wrtn" | paste -sd+ | bc) K)
  # 
  # DM_INFO=$(echo "${DISK_INFO}" | jq -r "select(.disk_device | startswith(\"dm\"))")
  # DM_READ=$( human $(echo "${DM_INFO}" | jq -r ".kB_read" | paste -sd+ | bc) K)
  # DM_WRITE=$( human $(echo "${DM_INFO}" | jq -r ".kB_wrtn" | paste -sd+ | bc) K)
  # 
  # DISK="disk:[sd:${SD_READ}/${SD_WRITE},md:${MD_READ}/${MD_WRITE},dm:${DM_READ}/${DM_WRITE}]"
  CPU="cpu:$(iostat -o JSON | jq -r '.sysstat.hosts | .[] | .statistics | .[] | .["avg-cpu"] | .idle')"  
  RAM="mem:$(free -h | grep Mem | awk '{ print $7 }')"
     
  echo $(get_weather) $(get_raid_status) $(get_minikube_status) ${SOUND} ${IPADDR} ${NETWORK} ${CPU} ${RAM} ${DISK} home:$(space /home) root:$(space root--debian) flr:$(space /media/floor)
  sleep 2
  
done
# 
