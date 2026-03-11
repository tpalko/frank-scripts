#!/bin/bash 

set -e 

function log {
  MSG="$1"
  LOG_OP_FILE=0
  TEE_ARGS=
  LOG_OP_OUT=0
  [[ -n $LOG_FILE ]] && LOG_OP_FILE=1 && TEE_ARGS="-a $LOG_FILE"
  [[ $VERBOSE -eq 1 ]] && LOG_OP_OUT=1
  
  if [[ $LOG_OP_OUT -eq 1 ]]; then 
    echo "${MSG}" | tee $TEE_ARGS
  elif [[ $LOG_OP_FILE -eq 1 ]]; then 
    echo "${MSG}" >> $LOG_FILE 
  fi 
}

function get_current_control() {
  case ${OUTPUT_SETTING} in
    speakers)   echo ${FS_VOL_SPEAKER_CONTROL};;
    headphones)	echo ${FS_VOL_HEADPHONE_CONTROL};;    
  esac 
}

function write_output_setting {
  SETTING=$1
  log "Writing ${SETTING} to ~/.vol-outputsetting"
  echo -n ${SETTING} > ~/.vol-outputsetting 
  read_output_setting
}

function read_output_setting() {
  OUTPUT_SETTING_DEFAULT=speakers
  [[ -s ~/.vol-outputsetting ]] || (
    log "no output set, writing default" \
      && write_output_setting $OUTPUT_SETTING_DEFAULT
  )

  OUTPUT_SETTING=$(cat ~/.vol-outputsetting)
}

function parse_amixer() {
  AMIXER_OUTPUT="$1"
  # log "parsing amixer output: ${AMIXER_OUTPUT}"
  if [[ $(get_current_control) = ${FS_VOL_HEADPHONE_CONTROL} ]]; then 
    [[ $(echo "$AMIXER_OUTPUT" | grep -E "^\s+Front Left" | awk '{ print $5 }') =~ \[([0-9]+)%\] ]]
  else 
    [[ $(echo "$AMIXER_OUTPUT" | grep -E "^\s+Mono" | awk '{ print $4 }') =~ \[([0-9]+)%\] ]]
  fi 
  echo ${BASH_REMATCH[1]}
}

function amixer_call() {  
  amixer -D default $@ 2>&1
}

function get_control_value {
  KEY=$1
  amixer_call -D default get ${KEY}
}

function set_card_value {
  KEY=$1
  VALUE=$2
  amixer_call -D default set ${KEY} ${VALUE}
}

function read_vol() {
  VOL=$(parse_amixer "$(get_control_value $(get_current_control))")
}

function init() {
  #set_card_value Surround 0%
  #set_card_value Center 0%
  #set_card_value LFE 0%
  set_card_value PCM 100%  
  set_card_value Front 100%
  set_card_value ${FS_VOL_HEADPHONE_CONTROL} on
}

function set_current_card_value() {
  VALUE=$1
  CONTROL=$(get_current_control)
  
  set_card_value ${CONTROL} ${VALUE}
}

function set_vol() {
  CHANGE=$1
  init
  TO_VOL=$(( ${VOL} + ${CHANGE} ))
  log "Setting ${OUTPUT_SETTING} to ${TO_VOL}%"
  set_current_card_value ${TO_VOL}%
}

function set_noncurrent_card_value() {
  VALUE=$1
  CONTROL=
  case ${OUTPUT_SETTING} in
    speakers)   CONTROL=${FS_VOL_HEADPHONE_CONTROL};;
    headphones)	CONTROL=${FS_VOL_SPEAKER_CONTROL};;		
    *)		echo "No audio setting: ${OUTPUT_SETTING}" && return;;
  esac 
  set_card_value ${CONTROL} ${VALUE}
}

function reset() {
  init 
  INPUT=$1
  TO_VOL=${INPUT:-0}
  
  set_current_card_value ${TO_VOL}%
  set_noncurrent_card_value 0%
}

## exposed commands

function set_output_to() {
  SET_TO=$1  
  if [[ "${OUTPUT_SETTING}" != "${SET_TO}" ]]; then 
    write_output_setting ${SET_TO}
    reset
  else 
    log "output already set to ${SET_TO}"
  fi 
}

function shift_output_to() {
  SHIFT_TO=$1  
  if [[ "${OUTPUT_SETTING}" != "${SHIFT_TO}" ]]; then 
    write_output_setting ${SHIFT_TO}
    reset ${VOL}
  fi 
}


#export FS_VOL_SPEAKER_CONTROL="Speaker"
export FS_VOL_SPEAKER_CONTROL="Master"
export FS_VOL_HEADPHONE_CONTROL="Headphone"
export OUTPUT_SETTING
export VOL 

VERBOSE=0
ACTION=
SUBACTION=
LOG_FILE=
#CARD=3
#DEVICE_PRODUCT_NAME="Family 17h/19h/1ah HD Audio Controller"
#DEVICE_PRODUCT_NAME="Sunrise Point-LP HD Audio"
# DEVICE_PRODUCT_NAME="Starship/Matisse HD Audio Controller"
# CARD=$(pactl -f json list cards | jq -r ".[] | .properties | select(.[\"device.product.name\"] == \"${DEVICE_PRODUCT_NAME}\") | .[\"alsa.card\"]")
# log "Found card ${CARD} for ${DEVICE_PRODUCT_NAME}"

while [[ $# -gt 0 ]]; do 
  case $1 in 
    -v)                               VERBOSE=1; shift;;
    -l)                               LOG_FILE=$2; shift; shift;;
    -c)                               CARD=$2; shift; shift;;
    up|down|get)                      ACTION=$1; shift;;
    set|shift)                        ACTION=$1; SUBACTION=$2; shift; shift;;
    *)                                echo "$1 not recognized"; shift;;
  esac 
done 

read_output_setting
read_vol

log "Action=${ACTION} Card=${CARD} OUTPUT_SETTING=${OUTPUT_SETTING} VOL=${VOL}"

case ${ACTION} in 
    up)         set_vol 5;;
    down)       set_vol -5;;
    get)        echo "${VOL} ${OUTPUT_SETTING}";;
    set)	      set_output_to ${SUBACTION};;
    shift)      shift_output_to ${SUBACTION};;
esac 
