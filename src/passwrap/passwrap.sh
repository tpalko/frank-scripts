#!/bin/bash 


function usage() {
  echo "Usage: $0 wrap|unwrap FOLDER"
}

[[ $# -lt 2 || ("${1}" != "wrap" && "${1}" != "unwrap") ]] && usage && exit 1

ACTION=$1
FOLDER=$2

[[ "${ACTION}" = "wrap" ]] && gpgtar -r tpalko --encrypt --output ${FOLDER}_$(date +%Y%m%d%H%M%S).tar.gz.gpg ${FOLDER} && rm -rf ${FOLDER}
[[ "${ACTION}" = "unwrap" ]] && gpgtar --decrypt ${FOLDER}_*.tar.gz.gpg && rm -f ${FOLDER}_*.tar.gz.gpg
