#!/bin/bash 

set -e
# set -x

export SAVE_BAK=0
export INTERACTIVE=1
export VERBOSE=0

while [[ $# -gt 0 ]]; do 
  case $1 in
    -y) INTERACTIVE=0
        shift
        ;;
    -s) SAVE_BAK=1
        shift
        ;;
    -v) VERBOSE=1
        shift 
        ;;
     *) NAME=$1
        shift 
        ;;
  esac 
done 

[[ -z "${NAME}" ]] && echo "no NAME given" && exit 1

NOW=$(date)
HUMAN_TIMESTAMP=$(date -d "${NOW}" +%Y%m%dT%H%M%S)
UNIX_TIMESTAMP=$(date -d "${NOW}" +%s)
BAK_FOLDER=.${NAME}
ARCHIVE_FILENAME=${NAME}.tar.gz
ENCRYPTED_FILENAME=${NAME}.tar.gz.gpg

FLAGS=""
GPG_FLAGS=""

if [[ ${INTERACTIVE} -eq 0 ]]; then 
  GPG_FLAGS="${GPG_FLAGS} --yes"
fi 

if [[ ${VERBOSE} -eq 1 ]]; then 
  FLAGS="${FLAGS} -v"
  GPG_FLAGS="${GPG_FLAGS} -v"
else 
  GPG_FLAGS="${GPG_FLAGS} -q"
fi 

if [[ ${VERBOSE} -eq 1 ]]; then 
  echo "GPG_FLAGS=${GPG_FLAGS}"
  echo "FLAGS=${FLAGS}"
fi 

function confirm() {
  local MSG="$1"
  [[ ${INTERACTIVE} -eq 0 ]] && return 0
  [[ -n ${MSG} ]] && echo "${MSG}"
  echo -n "ok? y/N "
  read OK
  [[ $OK =~ y|Y ]]
}

# NAME=private
# unpacked folder will always be "private"
# packed archive will be private.tar.gz.gpg.box.[0-9]+
# if "private" folder, pack and encrypt to .box.tmp, bump all indexed files to make room for .0, rename .tmp to .0
# if private.tar.gz, continue to encrypt to .box.tmp, etc.
# if private.tar.gz.gpg, bump others and rename to .box.0
# iff all versions are .box.# files do we decrypt and unpack

function run() {
  CMD="$@"
  ${CMD} || (CAP=$? && echo "Failed" && exit ${CAP})
}

function log() {
  local MSG="$1"
  if [[ ${VERBOSE} -eq 1 ]]; then
    echo "${MSG}"
  fi 
}

function cleanup() {
  OBJ="$1"
  if [[ ${SAVE_BAK} -eq 1 ]]; then
    run mkdir -p ${FLAGS} ${BAK_FOLDER}
    run mv -n ${FLAGS} ${OBJ} ${BAK_FOLDER}/${OBJ}.${UNIX_TIMESTAMP}
  else 
    rm -rf ${FLAGS} ${OBJ}
  fi 
}

# -- accepts filename.tar.gz.gpg, no residue
function box_archive() {
  OBJ="$1"
  STAT_DATE=$(date -d $(stat ${OBJ} | grep Modify | awk '{ print $2"T"$3 }') +%Y%m%dT%H%M%S)
  run mv -n ${FLAGS} ${OBJ} ${OBJ}.${STAT_DATE}.box
  echo "${OBJ}.${STAT_DATE}.box created"
}

# -- accepts filename.tar.gz
function encrypt_archive() {
  OBJ="$1"
  log "encrypting ${OBJ}"
  run gpg ${GPG_FLAGS} -e -u ${USER} -r ${USER} ${OBJ}
  cleanup ${OBJ}
  box_archive ${OBJ}.gpg
}

# -- accepts filename folder
function archive_folder() {
  OBJ="$1"
  run tar ${FLAGS} --verify -cf ${OBJ}.tar ${OBJ}
  run gzip ${FLAGS} ${OBJ}.tar
  run gzip -t ${FLAGS} ${ARCHIVE_FILENAME}
  cleanup ${OBJ}
  encrypt_archive ${ARCHIVE_FILENAME}
}

if [[ -f ${ENCRYPTED_FILENAME} ]]; then 
  box_archive ${ENCRYPTED_FILENAME}
  exit 0
fi 

if [[ -f ${ARCHIVE_FILENAME} ]]; then 
  encrypt_archive ${ARCHIVE_FILENAME}
  exit 0
fi 

if [[ -d ${NAME} ]]; then 
  archive_folder ${NAME}
  exit 0
fi 

LAST_BOXFILE=$(find . -path "./${NAME}.tar.gz.gpg.[0-9T]*.box" | sort -n -r | head -n 1)

if [[ -n ${LAST_BOXFILE} ]]; then 

  confirm "extract ${LAST_BOXFILE}?"
  run gpg ${GPG_FLAGS} -d ${LAST_BOXFILE} | tar -xz ${FLAGS}
  echo "${LAST_BOXFILE} unboxed"

else 

  echo "no boxfiles found"

fi 
