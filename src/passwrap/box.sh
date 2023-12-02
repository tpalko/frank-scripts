#!/bin/bash 

NAME=$1
BAK=.${NAME}_$(date +%s)
FILENAME=box_${NAME}
SAVE_BAK=0
MODE=

# state machine:
# named folder --> archive (intermittent/failed state) --> encrypted archive --> named folder 
# each 'if' block represents one move '-->'
# the first two moves set MODE=boxing
# MODE=boxing blocks the third move (script must start with 'encrypted archive' in order to moved to 'named folder')

# -- if the named folder exists pack it up
if [[ -d "${NAME}" ]]; then 
  MODE=boxing
  echo "Found folder ${NAME}, packing ${NAME}.."
  # -- archive and remove folder 
  (tar -czvf ${FILENAME}.tar.gz ${NAME} && rm -rvf ${NAME}) || echo "could not archive ${NAME}"
  # -- if we're saving backups, make the backup folder 
  [[ ${SAVE_BAK} -ne 0 ]] && mkdir -vp ${BAK}
  # -- if the archive doesn't exist (presumably because the archiving failed) delete the backup folder (it's empty)
  if [[ ! -f ${FILENAME}.tar.gz ]]; then 
    rm -rf ${BAK}
    exit 1
  fi 
  # -- an encrypted archive already exists, so we have to move it out of the way 
  if [[ -f ${FILENAME}.tar.gz.gpg ]]; then 
    # -- move to backup folder if we're saving backups
    if [[ ${SAVE_BAK} -ne 0 ]]; then 
      mv -v ${FILENAME}.tar.gz.gpg ${BAK}/${FILENAME}.tar.gz.gpg.old
      echo "saved off existing .tar.gz.gpg to .tar.gz.gpg.old"
    else 
      echo "not saving off existing .tar.gz.gpg, will attempt to overwrite"
    fi 
  fi 
fi 

# -- if the archive file exists, encrypt it
if [[ -f "${FILENAME}.tar.gz" ]]; then 
  MODE=boxing
  # -- on successful encryption, move everything else to the backup folder or delete it
  gpg -e -u ${USER} -r ${USER} ${FILENAME}.tar.gz \
    && ([[ ${SAVE_BAK} -ne 0 ]] && mv -v ${NAME} ${FILENAME}.tar.gz ${BAK}) || (echo "not saving bak" && rm -rvf ${NAME} ${FILENAME}.tar.gz)
fi 

# -- if the previous steps haven't been packing things up, unpack the encrypted archive 
if [[ -z "${MODE}" ]]; then 
  if [[ -f "${FILENAME}.tar.gz.gpg" ]]; then 
    echo "unpacking ${FILENAME}.tar.gz.gpg.."
    gpg -d ${FILENAME}.tar.gz.gpg | tar -xzv
  else
    echo "neither folder ${NAME} nor file ${FILENAME}.tar.gz.gpg exist" && exit 1
  fi
fi 
