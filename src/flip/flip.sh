#!/bin/bash 

START=0
CURR=${START}
STAT="--stat"

function menu() {

  [[ -n "${SEL}" ]] && OPT=${SEL} && unset SEL

  if [[ -z "${OPT}" ]]; then   
    echo -n "(f)ull  (c)ompact  (p)revious  (n)ext  (q)uit  >> "
    read OPT
  fi 

  case ${OPT} in 
    f)	STAT=""
	;;
    c)  STAT="--stat"
	;;
    n)  STAT="--stat"
        CURR=$(( CURR + 1 ))
	;;
    p)  STAT="--stat"
     	CURR=$(( CURR - 1 ))
	;;
    q)	exit 0
	;;
    *)  return 1
	;;
  esac 

  unset OPT 

  [[ ${CURR} -lt 0 ]] && CURR=0

  return 0
}

HEADER="*****************************************************************************\n***********************************************************\n**************************************\n**************\n****\n****\t\t"
FOOTER="****\n*******************\n*****************************************\n**************************************************************************\n****************************************************************"

while :; do 

  echo "Showing ${CURR}"

  if [[ -z "${STAT}" ]]; then 
    PREV=$(( CURR + 1 ))
    OUTPUT="$(script -q /dev/null git --no-pager diff --pickaxe-all HEAD~${PREV}..HEAD~${CURR} $@)"
  else 
    OUTPUT="$(script -q /dev/null git show --pickaxe-all ${STAT} HEAD~${CURR} $@)"
  fi  

  #OUTPUT="$(script -q /dev/null git --no-pager show --pickaxe-all ${STAT} HEAD~${CURR} $@)"
 
  if [[ -n "${OUTPUT}" ]]; then 
    printf "${HEADER}"
    printf "\n"
    echo -n "${OUTPUT}"
    printf "\n"
    printf "${FOOTER}"
    printf "\n\n"
  fi 

  [[ -z "${OUTPUT}" ]] && SEL=n 

  while :; do 
    menu ${SEL} && break 
  done 

done 

