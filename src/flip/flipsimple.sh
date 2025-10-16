#!/bin/bash 

N=0
BREAK=0

while :; do

  git show HEAD~${N} --stat --oneline
  CAUGHT=0
  while [[ ${CAUGHT} -eq 0 ]]; do 
    echo "(f)ull"
    echo "(n)ext"
    echo "(q)uit"
    echo -n "? "
    read ANS
    case ${ANS} in
      f)  git show HEAD~${N}
          CAUGHT=1
          ;;
      n)  N=$(( ${N} + 1 ))
          CAUGHT=1
          ;;
      q)  BREAK=1
          CAUGHT=1
          ;;
    esac 
  done 
  [[ ${BREAK} -eq 1 ]] && break 
done
