#!/bin/bash 


# state machine:
# named folder --> archive (intermittent/failed state) --> encrypted archive --> named folder 
# each 'if' block represents one move '-->'
# the first two moves set MODE=boxing
# MODE=boxing blocks the third move (script must start with 'encrypted archive' in order to moved to 'named folder')

export SAVE_BAK=0
export INTERACTIVE=1

while [[ $# -gt 0 ]]; do 
  case $1 in
    -y) INTERACTIVE=0
        shift
        ;;
    -s) SAVE_BAK=1
        shift
        ;;
     *) NAME=$1
        shift 
        ;;
  esac 
done 

[[ -z "${NAME}" ]] && echo "no NAME given" && exit 1

UNIX_TIMESTAMP=$(date +%s)
BAK=.${NAME}_${UNIX_TIMESTAMP}
FILENAME=box_${NAME}
MODE=
[[ ${INTERACTIVE} -eq 0 ]] && ASSUME_YES="--yes" || ASSUME_YES=

function confirm() {
  [[ ${INTERACTIVE} -eq 0 ]] && return 0
  echo -n "ok? y/N "
  read OK
  [[ "${OK}" != "y" ]] && echo "Not OK!" && return 1 || return 0
}

# -- if the named folder exists pack it up
if [[ -d "${NAME}" ]]; then 
  MODE=boxing
  echo "Found folder ${NAME}, packing ${NAME}.."
  # -- archive and remove folder 
  (
    tar -czvf ${FILENAME}.tar.gz ${NAME} \
      && rm -rvf ${NAME}
  ) || echo "could not archive ${NAME}"  
fi 

# -- if the archive file exists, encrypt it
if [[ -f ${FILENAME}.tar.gz ]]; then 
  MODE=boxing

  # -- an encrypted archive already exists, so we have to move it out of the way 
  if [[ -f ${FILENAME}.tar.gz.gpg ]]; then 
    # -- move to backup folder if we're saving backups
    if [[ ${SAVE_BAK} -ne 0 ]]; then 
      # -- if we're saving backups, make the backup folder 
      mkdir -vp ${BAK}      
      mv -v ${FILENAME}.tar.gz.gpg ${BAK}/${FILENAME}.tar.gz.gpg.${UNIX_TIMESTAMP}
      echo "saved off existing .tar.gz.gpg to .tar.gz.gpg.${UNIX_TIMESTAMP} (SAVE_BAK=${SAVE_BAK})"
    else 
      echo "not saving off existing .tar.gz.gpg, will attempt to overwrite (SAVE_BAK=${SAVE_BAK})"
      confirm || exit 1
    fi 
  fi 

  # -- on successful encryption, move everything else to the backup folder or delete it
  (
    [[ ${SAVE_BAK} -eq 0 ]] \
      && echo "not saving archive after encryption" \
      && confirm
  ) \
    || [[ ${SAVE_BAK} -ne 0 ]] \
    && gpg ${ASSUME_YES} -e -u ${USER} -r ${USER} ${FILENAME}.tar.gz \
    && (
      (
        [[ ${SAVE_BAK} -ne 0 ]] \
          && mkdir -vp ${BAK} \
          && mv -v ${FILENAME}.tar.gz ${BAK}/${FILENAME}.tar.gz.${UNIX_TIMESTAMP}
      ) \
        || (
          echo "not saving original folder or any leftover archives (SAVE_BAK=${SAVE_BAK})" \
            && rm -v ${FILENAME}.tar.gz
        )
    ) \
        || (
          echo "user aborted encryption of ${FILENAME}.tar.gz or it simply failed"
        )
fi 

# -- if the previous steps haven't been packing things up, unpack the encrypted archive 
if [[ -z "${MODE}" ]]; then 
  if [[ -f ${FILENAME}.tar.gz.gpg ]]; then 
    if [[ ! -d ${NAME} ]]; then 
      echo "decrypting and extracting ${FILENAME}.tar.gz.gpg.."
      gpg ${ASSUME_YES} -d ${FILENAME}.tar.gz.gpg | tar -xzv
    else 
      echo "would unpack ${FILENAME}.tar.gz.gpg except folder ${NAME} is in the way"
    fi 
  else
    echo "neither folder ${NAME} nor file ${FILENAME}.tar.gz.gpg exist" && exit 1
  fi
fi 
