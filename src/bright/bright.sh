#!/bin/bash

DIRECTIONS=( up down )
DEFAULT_DIRECTION=down
INPUT=$1
STEP=250

function get_current() {
  CURRENT=$(brightnessctl | grep -i "current brightness" | awk '{ print $3 }')
}

function change() {
  [[ " ${DIRECTIONS[@]} " =~ " ${INPUT} " ]] || exit 1
  CHANGE=$([[ ${INPUT} = up ]] && echo ${STEP} || echo -${STEP}) 
  brightnessctl s $(( $CURRENT + ${CHANGE} )) > /dev/null
  get_current
  show
}

function show() {
  echo ${CURRENT}
}

get_current
[[ -n ${INPUT} ]] && change || show 
