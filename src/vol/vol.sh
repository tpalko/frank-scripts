#!/bin/bash 

export FS_VOL_SPEAKER_CONTROL="Speaker"
export FS_VOL_HEADPHONE_CONTROL="Headphone"

function log {
  if [[ ${VERBOSE} -eq 1 ]]; then 
    echo "$1"
  fi 
}

function parse_amixer() {
  [[ $(echo "$1" | grep -E "^\s+Front Left" | awk '{ print $5 }') =~ \[([0-9]+)%\] ]]
  echo ${BASH_REMATCH[1]}
}

function get_vol() {
  log "Getting ${CUSTOM_AUDIO}"
  case ${CUSTOM_AUDIO} in
    speakers)	  VOL=$(parse_amixer "$(get_card_value ${FS_VOL_SPEAKER_CONTROL})");;
    headphones)	VOL=$(parse_amixer "$(get_card_value ${FS_VOL_HEADPHONE_CONTROL})");;
    *)	        echo "No audio setting: ${CUSTOM_AUDIO}";;
  esac 
}

function init() {
  #set_card_value Surround 0%
  #set_card_value Center 0%
  #set_card_value LFE 0%
  set_card_value PCM 100%
  set_card_value Master 100%
  set_card_value ${FS_VOL_HEADPHONE_CONTROL} on
}

function reset() {
  init 
  TO_VOL=$1
  
  if [[ -z "${TO_VOL}" ]]; then 
    set_card_value ${FS_VOL_SPEAKER_CONTROL} 0%
    set_card_value ${FS_VOL_HEADPHONE_CONTROL} 0%
  else
    case ${CUSTOM_AUDIO} in 
      speakers)   set_card_value ${FS_VOL_SPEAKER_CONTROL} ${TO_VOL}%
                  set_card_value ${FS_VOL_HEADPHONE_CONTROL} 0%
                  ;;
     headphones)  set_card_value ${FS_VOL_HEADPHONE_CONTROL} ${TO_VOL}%
                  set_card_value ${FS_VOL_SPEAKER_CONTROL} 0%
                  ;;
    esac 
  fi 
}

function set_vol() {
  init
  TO_VOL=$(( ${VOL} + ${CHANGE} ))
  log "Setting ${CUSTOM_AUDIO} to ${TO_VOL}%"
  case ${CUSTOM_AUDIO} in
    speakers)   set_card_value ${FS_VOL_SPEAKER_CONTROL} ${TO_VOL}%
                ;;
    headphones)	set_card_value ${FS_VOL_HEADPHONE_CONTROL} ${TO_VOL}%
                ;;
		
    *)		echo "No audio setting: ${CUSTOM_AUDIO}";;
  esac 
}

function set_to() {
  SET_TO=$1  
  if [[ "${CUSTOM_AUDIO}" != "${SET_TO}" ]]; then 
    write_audio_settings ${SET_TO}
    reset
  fi 
}

function shift_to() {
  SHIFT_TO=$1  
  if [[ "${CUSTOM_AUDIO}" != "${SHIFT_TO}" ]]; then 
    write_audio_settings ${SHIFT_TO}
    reset ${VOL}
  fi 
}

function get_card_value {
  KEY=$1
  CMD="amixer -c ${CARD} get ${KEY}"
  ${CMD} 2>&1
}

function set_card_value {
  KEY=$1
  VALUE=$2
  CMD="amixer -c ${CARD} set ${KEY} ${VALUE}"
  ${CMD} 2>&1
}

function write_audio_settings {
  SETTING=$1
  log "Writing ${SETTING} to ~/.customaudio"
  echo -n ${SETTING} > ~/.customaudio 
  load_current
}

set -e 

function load_current() {
  [[ -f ~/.customaudio ]] || write_audio_settings speakers
  CUSTOM_AUDIO=$(cat ~/.customaudio)
}



VERBOSE=0
ACTION=
SUBACTION=
#CARD=3
#DEVICE_PRODUCT_NAME="Family 17h/19h/1ah HD Audio Controller"
#DEVICE_PRODUCT_NAME="Sunrise Point-LP HD Audio"
DEVICE_PRODUCT_NAME="Starship/Matisse HD Audio Controller"
CARD=$(pactl -f json list cards | jq -r ".[] | .properties | select(.[\"device.product.name\"] == \"${DEVICE_PRODUCT_NAME}\") | .[\"alsa.card\"]")

while [[ $# -gt 0 ]]; do 
  case $1 in 
    -v)                               VERBOSE=1; shift;;
    -c)                               CARD=$2; shift; shift;;
    up|down|get)                      ACTION=$1; shift;;
    set|shift)                        ACTION=$1; SUBACTION=$2; shift; shift;;
    *)                                echo "$1 not recognized"; shift;;
  esac 
done 

log "Action=${ACTION}"

load_current
get_vol

case ${ACTION} in 
    up)         CHANGE=5; set_vol;;
    down)       CHANGE=-5; set_vol;;
    get)        echo "${VOL}";;
    set)	      set_to ${SUBACTION};;
    shift)      shift_to ${SUBACTION};;
esac 
