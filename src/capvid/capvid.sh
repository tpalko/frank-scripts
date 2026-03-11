#!/bin/bash 

TARGET_FOLDER=.
DESC=
THREAD_QUEUE_SIZE=2048

while [[ $# -gt 0 ]]; do 
  case $1 in 
    -f) TARGET_FOLDER=$2
        shift; shift
	      ;;
    -d) DESC=$2_
        shift; shift
	      ;;
    -q) THREAD_QUEUE_SIZE=$2
        shift; shift
        ;;
    *)  echo "done reading options.."
        break
        ;;
  esac
done 

FILE=${TARGET_FOLDER}/$(date +%Y%m%d)_${DESC}$(date +%s).mkv
echo "Writing to ${FILE}.."
echo "-thread_queue_size ${THREAD_QUEUE_SIZE}"
echo "Adding $@"

TQS="-thread_queue_size ${THREAD_QUEUE_SIZE}"

INPUT=${DISPLAY:-:0}
INPUT_OFFSET="+0,0"
VIDEO_SIZE=$(xdpyinfo | awk '/dimensions/{print $2}')

# -video_size 3840x1080
CMD="ffmpeg -framerate 30 -f x11grab -video_size "${VIDEO_SIZE}" $TQS -i ${INPUT}${INPUT_OFFSET} -f pulse $TQS -i 0 ${FILE}"
echo ${CMD}

echo -n "OK? y/N "
read OK
[[ ! $OK =~ y|Y ]] && exit 1
${CMD} 
