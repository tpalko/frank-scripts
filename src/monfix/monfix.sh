#!/bin/bash

if [[ -f ~/.xsessionrc ]]; then 
  echo "Sourcing ~/.xsessionrc"
  . ~/.xsessionrc
else 
  echo "No ~/.xsessionrc"
fi 
