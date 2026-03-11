#!/bin/bash

#   for MOUNT in /home /media/storage /var/lib/docker /media/orange-storange; do 
#     echo -n "${MOUNT}:$(df ${MOUNT} | grep -v Filesystem | awk '{ print $4"/"$5 }') "
#   done

function get_minikube_status() {
  MINIKUBE_PATH=minikube # /home/debian/tpalko/.asdf/shims/minikube
  FULL_STATUS=$(${MINIKUBE_PATH} status 2>&1)
  MINIKUBE_STATUS=$(echo "${FULL_STATUS}" | grep -E "^host" | awk '{ print $2 }')
#  printf "\n\n\
#******************************************************** \n\n\
#$(date +%Y-%m-%dT%H:%M:%S) \n\
#path: ${PATH} \n\
#env: $(env | sort) \n \
#cluster: $(kubectl cluster-info) \n \
#kubectl: $(kubectl version) \n \
#docker: $(docker version) \n \
#go: $(go env | sort) \n \
#which minikube: $(which minikube) \n\
#minikube path: ${MINIKUBE_PATH} \n\
#${FULL_STATUS} \n\
#****************************************************" >> ~/baraction-minikube-status.log
  echo "[minikube:${MINIKUBE_STATUS}]"
}

function get_raid_status() {
  if [[ -s ~/.baraction-raidstatus ]]; then 
    STATUS=
    WROTE=0
    while read DEV; do 
      if [[ ${WROTE} -eq 1 ]]; then 
        STATUS="${STATUS} "
      fi 
      STATUS="${STATUS}${DEV}"
      WROTE=1
    done < <(cat ~/.baraction-raidstatus | jq -r ".devices | .[] | .device+\" \"+.size+\" \"+.status")    
    echo -n "[${STATUS}] "
  else 
    echo ""
  fi 
}

function is_current() {
  local FILE=$1
  export CURRENT_MINUTES=$2

  AGE=$(( $(date +%s) - $(stat ${FILE} -c "%Y") ))
  TEST_TIME=$(python3 -c "import os; min = os.getenv('CURRENT_MINUTES'); print(f'{(60*float(min)):.0f}')")

  [[ -s ${FILE} && ${AGE} -lt ${TEST_TIME} ]]
}

function get_disk() {

  MINUTES=.5
  IOSTAT_INTERVAL=5
  IOSTAT_COUNT=2
  WATCH_DEVICES=4
  OUTPUT_FILE=~/.bar-diskactivity

  # TEST_TIME=$(python3 -c "import os; min = os.getenv('MINUTES'); print(f'{(60*float(min)):.0f}')")
  
  if ! is_current ${OUTPUT_FILE} ${MINUTES} && [[ ! -f ${OUTPUT_FILE}.tmp ]]; then 
  # if [[ (! -f ${OUTPUT_FILE} || $(( $(date +%s) - $(stat ${OUTPUT_FILE} -c "%Y") )) -gt ${TEST_TIME}) && ! -f ${OUTPUT_FILE}.tmp ]]; then 
    ( iostat -j ID -d --dec=0 -o JSON ${IOSTAT_INTERVAL} ${IOSTAT_COUNT} > ${OUTPUT_FILE}.tmp )&
  fi 

  if [[ -f ${OUTPUT_FILE}.tmp ]]; then 
    cat ${OUTPUT_FILE}.tmp | jq >/dev/null 2>&1 \
      && rm -f ${OUTPUT_FILE} \
      && mv ${OUTPUT_FILE}.tmp ${OUTPUT_FILE}
  fi 

  if [[ -f ${OUTPUT_FILE} ]]; then 
    # - get the most recent statistics, and for all dm* disks, sort by throughput, reverse it, and take the top WATCH_DEVICES
    RESULTS=$(cat ${OUTPUT_FILE} | jq -j ".sysstat.hosts | .[] | .statistics | .[-1] | .disk | [.[] | select(.disk_device | startswith(\"dm\"))] | sort_by(.tps) | reverse | .[0:${WATCH_DEVICES}] | .[] | (.disk_device,\":\",.tps,\"\n\")" 2>/dev/null)
    [[ -n "${RESULTS}" ]] \
      && FORMATTED_RESULTS=$(echo "${RESULTS}" | sed 's/^.*-//' | tr '\n' ' ') \
      && echo ${FORMATTED_RESULTS%% } || echo "+"
  else 
    echo "- "
  fi 
}

function get_users() {
  SESSIONS=$(loginctl --no-pager --no-legend --full list-sessions)
  # SESSION UID USER  SEAT  TTY
  OUTPUT=$(echo ${SESSIONS} | awk '{ print $3 }' | tr '\n' ',')
  echo "${OUTPUT%%,} "
}

function set_raid_status() {

  LAST_UPDATED=-1 
  STATUS=
  if [[ -f ~/.baraction-raidstatus ]]; then 
    LAST_UPDATED=$(cat ~/.baraction-raidstatus | jq -r ".last_updated")
  fi 

  if [[ $? -ne 0 \
    || ${LAST_UPDATED} -eq -1 \
    || $(( $(date +%s) - ${LAST_UPDATED} )) -gt 5 ]]; then 

    if [[ -f /proc/mdstat ]]; then 
      
      DEVICES=($(cat /proc/mdstat | grep "active" | awk '{ print $1 }'))
      
      OUTFILE="{\"last_updated\":\"$(date +%s)\",\"devices\":["
      WROTE=0

      for DEVICE in ${DEVICES[@]}; do 
        if [[ ${WROTE} -eq 1 ]]; then 
          OUTFILE="${OUTFILE},"
        fi 
        # -- a syncing array
        #sync_action: recover
        #sync_completed: x/y
        #array_state: clean
        #state: in_sync
        # -- a normal array 
        #sync_action: idle 
        #sync_completed: none 
        #array_state: clean 
        #state: in_sync 
        #OUTPUT=; for THING in $(find /sys/class/block/md2/md/ -type f); do OUTPUT="${OUTPUT}$(basename $THING): $(cat $THING)\n"; done; printf "${OUTPUT}" | column -t
        ARRAY_SIZE=$(cat /sys/class/block/$DEVICE/md/component_size)
        ARRAY_SIZE_HUMAN=$(human $ARRAY_SIZE "K" 1)
        # - recover or idle
        SYNC_ACTION=$(cat /sys/class/block/$DEVICE/md/sync_action)
        ARRAY_STATE=$(cat /sys/class/block/$DEVICE/md/array_state)
        if [[ -n $SYNC_ACTION && $SYNC_ACTION != idle ]]; then 
          SYNC_COMPLETED=$(cat /sys/class/block/$DEVICE/md/sync_completed)
          SYNC_COMPLETED_PERCENT=$(eval "python -c \"print(f'{100*$SYNC_COMPLETED:.1f}')\"")
          STATUS="${SYNC_ACTION} ${SYNC_COMPLETED_PERCENT}%"
        else 
          STATUS=${ARRAY_STATE}
        fi
        
        #DETAIL="$(sudo mdadm --detail /dev/${DEVICE})"
	      #echo "${DETAIL}" > ~/.baraction-raidstatus-${DEVICE}-$(date +%s)
#        STATUS=$(echo "${DETAIL}" | grep -E "^\s+State" | awk '{ $1="";$2=""; print $0 }' | xargs)
	      #STATE="$(echo "${DETAIL}" | grep -E "^\s+State" | sed "s/State\s://" | xargs)"
        #REBUILD_STATUS="$(echo "${DETAIL}" | grep -E "^\s+Rebuild|\s+Resync" | awk '{ print $4 }' | xargs)"
        #if [[ -n ${REBUILD_STATUS} ]]; then 
        #  STATE="${STATE} ${REBUILD_STATUS}"
        #fi 
        OUTFILE="${OUTFILE}{\"device\":\"${DEVICE}\",\"size\":\"${ARRAY_SIZE_HUMAN}\",\"status\":\"${STATUS:--}\"}"
        WROTE=1
      done 

      OUTFILE="${OUTFILE}]}"

      echo ${OUTFILE} > ~/.baraction-raidstatus
    fi 
  fi 
}

function get_weather() {
  if [[ -f ~/.baraction-weather ]]; then 
    TEMPF="$(cat ~/.baraction-weather | jq -r '.current.temp_f')"
    COND=$(cat ~/.baraction-weather | jq -r ".current.condition.text")
    QUALITY_INDEX=$(cat ~/.baraction-weather | jq -r ".current.air_quality | .\"us-epa-index\"")
    QUALITY=$QUALITY_INDEX
    if [[ $SHELL = /bin/bash || $SHELL = /usr/bin/zsh ]]; then 
      case ${QUALITY_INDEX} in 
        1)  QUALITY=good
            ;;
        2)  QUALITY="moderate"
            ;;
        3)  QUALITY="light unhealthy"
            ;;
        4)  QUALITY="unhealthy"
            ;;
        5)  QUALITY="very unhealthy"
            ;;
        6)  QUALITY="hazardous"
            ;;
      esac
    # elif [[ $SHELL = /bin/fish ]]; then 
      # switch ${QUALITY_INDEX}
      #   case 1 
      #     QUALITY=good          
      #   case 2 
      #     QUALITY="moderate"          
      #   case 3 
      #     QUALITY="light unhealthy"          
      #   case 4 
      #     QUALITY="unhealthy"          
      #   case 5 
      #     QUALITY="very unhealthy"          
      #   case 6 
      #     QUALITY="hazardous"          
      # end
    fi 
    echo "${TEMPF}F/${COND}/${QUALITY} "
  else 
    echo "no weather data "
  fi 
}

function set_weather() {
  LAST_UPDATED=901
  if [[ -f ~/.baraction-weather ]]; then 
    LAST_UPDATED=$(cat ~/.baraction-weather | jq -r ".current.last_updated_epoch")
  fi 
  # if last updated for whatever reason isn't recent, then update 
  if [[ $? -ne 0 || -z "${LAST_UPDATED}" || $(( $(date +%s) - ${LAST_UPDATED} )) -gt 900 ]]; then 
    curl -s --url "http://api.weatherapi.com/v1/current.json?key=${WEATHER_KEY}&q=${WEATHER_ZIP}&aqi=yes" -o ~/.baraction-weather
  fi
}

function get_cpu() {

  # old ??
  # CPU="cpu:$(iostat -o JSON | jq -r '.sysstat.hosts | .[] | .statistics | .[] | .["avg-cpu"] | .idle')"  

  local CPU_AGE=1000
  # if [[ -f ~/.baraction-iostat ]]; then 
  #   CPU_AGE=$(( $(date +"%s") - $(date --date $(stat ~/.baraction-iostat | grep Modify | cut -d " " -f2-) +"%s") ))
  # fi 

  if [[ $CPU_AGE -gt 3 ]]; then 
    {
      iostat -d 1 1 -y -c -o JSON \
        | jq -r ".sysstat.hosts | .[] | .statistics | .[]" > ~/.baraction-iostat.tmp \
        && sleep 1 \
        && mv -f ~/.baraction-iostat.tmp ~/.baraction-iostat
    } &
  fi 

  # 
  

  local CPU_VAL="\?"
  if [[ -f ~/.baraction-iostat ]]; then 
    CPU_VAL=$(cat ~/.baraction-iostat | jq -r ".[\"avg-cpu\"] | .user+.system | floor")
  fi 

  echo "cpu:${CPU_VAL} "
}

function den2unit() {
  local DEN=$1
  if [[ $SHELL = /bin/bash ]]; then 
  case ${DEN} in 
    1) UNIT=B;;
    $(( 2 ** 10 )))  UNIT=K;;
    $(( 2 ** 20 )))  UNIT=M;;
    $(( 2 ** 30 )))  UNIT=G;;
    $(( 2 ** 40 )))  UNIT=T;;
    $(( 2 ** 50 )))  UNIT=P;;
    *)  UNIT=?;;
  esac
  # elif [[ $SHELL = /bin/fish ]]; then 
    # switch ${DEN}
    #   case 1 
    #     UNIT=B
    #   case $(( 2 ** 10 ))  
    #     UNIT=K
    #   case $(( 2 ** 20 ))  
    #     UNIT=M
    #   case $(( 2 ** 30 ))  
    #     UNIT=G
    #   case $(( 2 ** 40 ))  
    #     UNIT=T
    #   case $(( 2 ** 50 ))  
    #     UNIT=P
    #   case '*'  
    #     UNIT=?
    # end
  fi 
  echo ${UNIT}
}

function unit2den() {
  local UNIT=$1
  if [[ $SHELL = /bin/bash ]]; then 
  case ${UNIT} in
    B)  echo $(( 2 ** 0 ));;
    K)  echo $(( 2 ** 10 ));;
    M)  echo $(( 2 ** 20 ));;
    G)  echo $(( 2 ** 30 ));;
    T)  echo $(( 2 ** 40 ));;
    P)  echo $(( 2 ** 50 ));;
  esac 
  # elif [[ $SHELL = /bin/fish ]]; then 
    # switch ${UNIT}
    #   case B 
    #     echo $(( 2 ** 0 ))
    #   case K 
    #     echo $(( 2 ** 10 ))
    #   case M 
    #     echo $(( 2 ** 20 ))
    #   case G 
    #     echo $(( 2 ** 30 ))
    #   case T 
    #     echo $(( 2 ** 40 ))
    #   case P 
    #     echo $(( 2 ** 50 ))
    # end 
  fi 
}

function human() {
  
  SIZE=$1
  UNIT=$2
  UNIT_THRES_DEFAULT=10
  UNIT_THRES=$3
  UNIT_THRES=${UNIT_THRES:-${UNIT_THRES_DEFAULT}}

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
  while [[ ${FREE} -gt $(( ${DEN} * 1024 * ${UNIT_THRES} )) ]]; do 
    DEN=$(( ${DEN} * 1024 ))
  done 
  
  UNIT=$(den2unit ${DEN})
  
  REPORT=$(eval "python -c \"print(f'{($FREE / $DEN):.1f}')\"")
  echo "${REPORT}${UNIT}"
  # echo $(( ${FREE} / ${DEN} ))${UNIT}  
}

function battery() {

  if ! command upower 2>/dev/null; then 
    return 
  fi 

  BATT_PERCENT=$(upower -b | grep -iE "percentage" | awk '{ print $2 }')
  BATT_STATE=$(upower -b | grep -iE "state" | awk '{ print $2 }')
  BATT_TIME=$(upower -b | grep -iE "time" | awk '{ print $4" "$5 }')

    # state:               discharging
    # time to empty:       2.0 hours
    # percentage:          94%

  if [[ -n ${BATT_PERCENT} || -n ${BATT_STATE} ]]; then 
    echo "batt:${BATT_PERCENT} ${BATT_STATE}/${BATT_TIME} "
  fi
}

function ram() {
  echo "mem:$(free -h | grep Mem | awk '{ print $7"/"$2 }') "
}

function sound() {
  # assuming vol is in use 
  # `vol get` will return a numeric level 
  # .customaudio will contain either "headphones" or "speakers"
  CUSTOMAUDIO=$(cat ~/.customaudio) 
  debugtime
  VOL_VAL_OUTPUT=$(vol get | sed "s/\([0-9]*\)\(\s*\)\([a-z]\?\)\(.*\)/\1\3/")
  echo "vol:${VOL_VAL_OUTPUT} "
}

function ipaddress() {
  INET=$(ip addr show ${INTERFACE} | grep inet)
  IPADDRESS=$([[ $INET =~ ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) ]] \
    && echo ${BASH_REMATCH[0]})
  
  echo "$IPADDRESS "
}

function network() {
  NETWORK=""
  SENDRATE="?"
  RECEIVERATE="?"
  if [[ $(groups | grep wheel 2>&1 > /dev/null) -eq 0 ]]; then 
    #(
    #  sudo iftop -n -N -B -t -i ${INTERFACE} -s 1 2>/dev/null 1> ~/.baraction-iftop
    #)&
    debugtime
    if [[ -f ~/.baraction-iftop ]]; then 
      SENDRATE=$(grep "Total send rate" ~/.baraction-iftop | awk '{ print $6 }')
      RECEIVERATE=$(cat ~/.baraction-iftop | grep "Total receive rate" | awk '{ print $6 }')
      NETWORK="u${SENDRATE}/d${RECEIVERATE} "
    # else
    #   NETWORK=" " #net:fixme "
    fi 
  fi 

  echo "${NETWORK}"
}

function conntrack() {
  echo -n "$(cat /proc/sys/net/netfilter/nf_conntrack_count) "
}

function disk_usage() {
  DISK_INFO=$(iostat -o JSON | jq -r ".sysstat.hosts | .[] | .statistics | .[] | .disk | .[]")
  
  SD_INFO=$(echo "${DISK_INFO}" | jq -r "select(.disk_device | startswith(\"sd\"))")
  SD_READ=$( human $(echo "${SD_INFO}" | jq -r ".kB_read" | paste -sd+ | bc) K)
  SD_WRITE=$( human $(echo "${SD_INFO}" | jq -r ".kB_wrtn" | paste -sd+ | bc) K)
  
  MD_INFO=$(echo "${DISK_INFO}" | jq -r "select(.disk_device | startswith(\"md\"))")
  MD_READ=$( human $(echo "${MD_INFO}" | jq -r ".kB_read" | paste -sd+ | bc) K)
  MD_WRITE=$( human $(echo "${MD_INFO}" | jq -r ".kB_wrtn" | paste -sd+ | bc) K)
  
  DM_INFO=$(echo "${DISK_INFO}" | jq -r "select(.disk_device | startswith(\"dm\"))")
  DM_READ=$( human $(echo "${DM_INFO}" | jq -r ".kB_read" | paste -sd+ | bc) K)
  DM_WRITE=$( human $(echo "${DM_INFO}" | jq -r ".kB_wrtn" | paste -sd+ | bc) K)
  
  DISK="disk:[sd:${SD_READ}/${SD_WRITE},md:${MD_READ}/${MD_WRITE},dm:${DM_READ}/${DM_WRITE}]"

  echo "${DISK} "
}

function space() {

  # old ?
  # SPACE="root:$(space /dev/mapper/frankenux--vg-root--debian) home:$(space /dev/mapper/frankenux--vg-home) flr:$(space /dev/mapper/bigwhouse--vg-floor)"

  DRIVE_NUM=3
  DF_BASE_OUT=$(df -x tmpfs -x squashfs -x overlay -x devtmpfs -T)
  DF_LINES=$(echo "$DF_BASE_OUT" | wc -l)
  local df_out="$(echo "$DF_BASE_OUT" | tail -n $(( $DF_LINES - 1 )) | grep -vE '^efivarfs|efi$')"
  # local df_out="$(df -x tmpfs -x squashfs -x overlay -x devtmpfs -T | grep -v Mounted)"
  local name_free_json="$(echo "$df_out" | awk 'function awk_human(size) { 
    free = 1024*size
    den = 1024
    while(free > den*1024*10){ 
      den = den * 1024 
    } 
    switch (den) {
      case 1: unit = "B"
      break
      case 1024: unit = "K"
      break
      case 1048576: unit = "M"
      break
      case 1073741824: unit = "G"
      break
      default: unit = "?"
    }
    free = free / den  
    out = sprintf("%s%s", int(free), unit)
    return out
  } { print "{\"name\":\""$7"\",\"avail_fmt\":\""awk_human($5)"\",\"avail\":"$5"}," }')"
  local jq_parse="sort_by(.avail) \
    | [.[] \
    | select(.name)] \
    | .[0:$DRIVE_NUM] \
    | .[] \
    | ((.name | split(\"/\")[-1]) // \"root\"),\":\",.avail_fmt,\" \""

  # ((.avail/1024 | floor)/1024 | floor)
  # \"G \"
  local OUT=$(echo "[ ${name_free_json} {} ]" | jq -j "$jq_parse")

#  DEVICE_PATH=$1
  
#  TOTAL=$(df -k 2>/dev/null | grep -E "^${DEVICE_PATH}" | awk '{ print $2 }')
#  USED=$(df -k 2>/dev/null | grep -E "^${DEVICE_PATH}" | awk '{ print $3 }')
#  AVAIL=$(df -k 2>/dev/null | grep -E "^${DEVICE_PATH}" | awk '{ print $4 }')
  
#  echo $(human $(( ${AVAIL} )) K)
   echo $OUT
}

function publicip() {
  if ! is_current ~/.baraction-publicip 30; then 
    echo < ~/.baraction-publicip > EOF
$(curl ifconfig.me) | xargs 
EOF
  fi 

  cat ~/.baraction-publicip
}

function debugtime() {
  if [[ ${DEBUG} -eq 1 ]]; then
    date
  fi 
}

function run() {
    
  while :; do
    set_weather
    set_raid_status
    echo "$(get_weather)$(get_users)$(battery)$(get_raid_status)$(sound)$(ipaddress)$(network)$(conntrack)$(get_cpu)$(ram)$(space)"
    sleep 2
  done
}

function setenv() {

  export WEATHER_KEY=4ed8498856b8430dbc840941221703
  export WEATHER_ZIP=15206
  export INTERFACE=enp42s0

  # go check out https://www.weatherapi.com/
  # and fix up .env.example -> .env 
  export DEBUG=${DEBUG:=0}
  # ENV_FILE=$(dirname $(readlink $0))/.env
  # echo "Exporting ${ENV_FILE}"
  # export $(cat ${ENV_FILE} | xargs)
  # env | sort -n
  export PATH=${PATH}:/home/debian/tpalko/.asdf/bin:/home/debian/tpalko/.asdf/shims 
  export ASDF_DIR=/home/debian/tpalko/.asdf
}

setenv && run 

# echo $SHLVL
# [[ ${SHLVL} -eq 2 ]] && setenv && run 
