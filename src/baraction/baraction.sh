#!/bin/bash 

#   for MOUNT in /home /media/storage /var/lib/docker /media/orange-storange; do 
#     echo -n "${MOUNT}:$(df ${MOUNT} | grep -v Filesystem | awk '{ print $4"/"$5 }') "
#   done
WEATHER_KEY=90498543f4654f0eb1b174055212502
WEATHER_ZIP=15206

function weather() {
  if [[ -f ~/.weather ]]; then 
    TEMPF="$(cat ~/.weather | jq -r '.current.temp_f')"
    COND=$(cat ~/.weather | jq -r ".current.condition.text")
    echo ${TEMPF}F/${COND}
  else 
    echo "no weather data"
  fi 
}

while :; do
  
  LAST_UPDATED=9999
  if [[ -f ~/.weather ]]; then 
    LAST_UPDATED=$(cat ~/.weather | jq -r ".current.last_updated_epoch")
  fi 
  if [[ $? -ne 0 || -z "${LAST_UPDATED}" || $(( $(date +%s) - ${LAST_UPDATED} )) -gt 900 ]]; then 
    curl -s --url "http://api.weatherapi.com/v1/current.json?key=${WEATHER_KEY}&q=${WEATHER_ZIP}&aqi=no" -o ~/.weather
  fi
  
  
  CUSTOMAUDIO=$(cat ~/.customaudio) 
  SOUND="VOL:$(vol get)${CUSTOMAUDIO::1}"
  
  IFTOP=$(sudo iftop -B -t -i enp9s0 -s 1)
  SENDRATE=$(echo "${IFTOP}" | grep "Total send rate" | awk '{ print $6 }')
  RECEIVERATE=$(echo "${IFTOP}" | grep "Total receive rate" | awk '{ print $6 }')
  
  NETWORK="u${SENDRATE}/d${RECEIVERATE}"
  
  CPU="cpu:$(iostat -o JSON | jq -r '.sysstat.hosts | .[] | .statistics | .[] | .["avg-cpu"] | .idle')"  
  RAM="ram:$(free -h | grep Mem | awk '{ print $7 }')"
  
  HOMEFREE="home:$(df -h 2>/dev/null | grep "/home" | awk '{ print $4 }')"  
  ROOT="root:$(df -h 2>/dev/null | grep 'root--debian' | awk '{ print $4 }')"
  STORAGE="storage:$(df -h 2>/dev/null | grep '/media/storage' | awk '{ print $4 }')"
  
  BACKUPFREE=$(df -h 2>/dev/null | grep '/media/orange-storange' | awk '{ print $4 }')
  if [[ ${BACKUPFREE} -eq 0 ]]; then 
    BACKUPAVAIL=$(df -k 2>/dev/null | grep '/media/orange-storange' | awk '{ print $2 }')
    BACKUPUSED=$(df -k 2>/dev/null | grep '/media/orange-storange' | awk '{ print $3 }')
    BACKUPFREE=$(( (${BACKUPAVAIL} - ${BACKUPUSED}) / (1024) ))Mb
  fi
  BACKUP="backup:${BACKUPFREE}"

     
  echo $(weather) ${SOUND} ${NETWORK} ${CPU} ${RAM} ${HOMEFREE} ${ROOT} ${STORAGE} ${BACKUP}
  sleep 2
done
# 
