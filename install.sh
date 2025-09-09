#!/bin/bash 

for FOLD in src/*; do 
  echo -n "Install ${FOLD#src\/}? y/N "; 
  read doit
  if [[ ${doit} = "y" ]]; then 
    for FILE in ${FOLD}/*.sh; do 
      FILE=${FILE#${FOLD}/}      
      [[ ${FILE} = "install.sh" ]] && continue 
      LINKED_FILE=/usr/local/bin/${FILE%.sh}
      ln -svf ${PWD}/${FOLD}/${FILE} ${LINKED_FILE}
    done
  fi 
done
