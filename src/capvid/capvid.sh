#!/bin/bash 

TARGET_FOLDER=.
DESC=

while [[ $# -gt 0 ]]; do 
  case $1 in 
    -f) TARGET_FOLDER=$2; shift; shift;
	;;
    -d) DESC=$2_; shift; shift;
	;;
  esac
done 

FILE=${TARGET_FOLDER}/$(date +%Y%m%d)_${DESC}$(date +%s).mkv
echo "Writing to ${FILE}.."

ffmpeg -video_size 3840x1080 -framerate 30 -f x11grab -i :0.0 -f pulse -i 1 ${FILE}
