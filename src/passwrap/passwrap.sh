#!/bin/bash 
# author: tim@palkosoftware.com

GPG_USER_ID=${USER}

function usage() {
  echo "Usage: $0 [-u GPG_USER_ID] wrap FOLDER|unwrap ARCHIVE"
}

function unwrap() {
  
  # -- the encryption file must exist
  # -- but the final folder may not exist
  ENCRYPTION_FILES=$(find . -name ${FOLDER}_*.tar.gz.gpg)
  ENCRYPTION_FILE_COUNT=$(echo "${ENCRYPTION_FILES}" | wc -l)
  ENCRYPTION_FILE=$(echo "${ENCRYPTION_FILES}" | head -n 1)

  ([[ ! -d ${FOLDER} && ${ENCRYPTION_FILE_COUNT} -eq 1 ]]) \
    && echo "${FOLDER} folder doesn't exist and there is one encryption file ${ENCRYPTION_FILE}, clear to unwrap" \
    || (ERRCAP=$? && echo "ERROR: folder ${FOLDER} already exists or there are no >or< too many encryption files (${ENCRYPTION_FILES})" && exit ${ERRCAP}) \
      || exit $?

  (gpg -d -o ${FOLDER}.tar.gz ${ENCRYPTION_FILE} && [[ -f ${FOLDER}.tar.gz ]]) \
    && (
      (echo "${ENCRYPTION_FILE} --> ${FOLDER}.tar.gz" && tar -xzvf ${FOLDER}.tar.gz && [[ -d ${FOLDER} ]]) \
        && ( 
          (echo "${FOLDER}.tar.gz --> ${FOLDER}" && rm -vf ${FOLDER}.tar.gz && rm -vf ${ENCRYPTION_FILE}) \
            && echo "All done!" \
            || echo "Cleanup failed"
        ) \
        || echo "Extraction failed"
    ) \
    || echo "Decryption failed"
  
  # && rm -vf ${ARCHIVE_GLOB} \
  # mkdir -v ${FOLDER} \
  #   && gpgtar --decrypt ${ARCHIVE_GLOB} \
  #   && [[ -d ${FOLDER} ]] \
  #   && echo "Archive expanded into ${FOLDER}"
}

function wrap() {

  if [[ ! -d ${FOLDER_PATH_OR_ARCHIVE} ]]; then 
    echo "${FOLDER_PATH_OR_ARCHIVE} is not a folder, will not wrap"
    exit 1
  fi 

  # -- neither the archive file nor the encrypted file can exist 
  # -- because we're adding a date, we need to check the glob for both
  # -- if we want to persist versions of either, we can mess with this
  ARCHIVE_FILE_COUNT=$(find . -name ${ARCHIVE_NAME}_*.tar.gz | wc -l)  
  ENCRYPTION_MATCHES=$(find . -name ${ARCHIVE_NAME}_*.tar.gz.gpg | wc -l)

  ([[ -d ${FOLDER} && ${ARCHIVE_FILE_COUNT} -eq 0 && ${ENCRYPTION_MATCHES} -eq 0 ]]) \
    && echo "Ready to wrap" \
    || (ERRCAP=$? && echo "ERROR: folder ${FOLDER} does not exist or there are archives (${ARCHIVE_FILE_COUNT}) or encrypted files (${ENCRYPTION_MATCHES})" && exit ${ERRCAP}) \
      || exit $?

  DATE_SUFFIX="_$(date +%Y%m%dT%H%M%S)"
  OUTPUT_ARCHIVE=${FOLDER}${DATE_SUFFIX}.tar.gz
  
  (tar -czvf ${OUTPUT_ARCHIVE} ${FOLDER} && [[ -f ${OUTPUT_ARCHIVE} ]]) \
    && (
      (echo "${FOLDER} --> ${OUTPUT_ARCHIVE}" && gpg -se -r ${GPG_USER_ID} ${OUTPUT_ARCHIVE} && [[ -f ${OUTPUT_ARCHIVE}.gpg ]]) \
        && (
          (echo "${OUTPUT_ARCHIVE} --> ${OUTPUT_ARCHIVE}.gpg" && rm -rvf ${FOLDER} && rm -vf ${OUTPUT_ARCHIVE}) \
            && echo "Cleaned up" \
            || echo "Cleanup failed"
        ) \
        || echo "Encryption failed"
    ) \
    || echo "Archiving failed"

  # gpgtar -r ${GPG_USER_ID} --encrypt --output ${OUTPUT_ARCHIVE} ${FOLDER}/ \
  #   && [[ -f ${OUTPUT_ARCHIVE} ]] \
  #   && echo "${OUTPUT_ARCHIVE} created"
}

[[ $# -lt 2 ]] && usage && exit 1

while [[ $# -gt 2 ]]; do 
  case $1 in 
    -u)   GPG_USER_ID=$2
          shift; shift 
          ;;
    *)    echo "Don't recognize $1"
          shift; shift 
          ;;
  esac 
done 

ACTION=$1
FOLDER_PATH_OR_ARCHIVE=$2

(gpg -k ${GPG_USER_ID} 2>&1 >/dev/null) \
  && echo "${GPG_USER_ID} exists, great!" \
  || (ERRCAP=$? && echo "ERROR: GPG USER-ID \"${GPG_USER_ID}\" has no key on this system" && exit ${ERRCAP}) \
    || exit $?

ARCHIVE_NAME=$(basename ${FOLDER_PATH_OR_ARCHIVE})
echo "Sanitized your input folder \"${FOLDER_PATH_OR_ARCHIVE}\" --> \"${ARCHIVE_NAME}\""
# ENCRYPTED_FILE=$(find . -name ${ARCHIVE_NAME}_*.tar.gz.gpg | head -n 1)

case ${ACTION} in 
  wrap|unwrap)  echo "${ACTION}ping ${ARCHIVE_NAME}"
                ${ACTION}
                ;;
  *)            usage; exit 1 
                ;;
esac 
