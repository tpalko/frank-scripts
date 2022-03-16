#!/bin/bash 

while read PACKAGE; do 
  echo "\"${PACKAGE}\": \"$(cat node_modules/${PACKAGE}/package.json | jq -r ".version")\","
done < <(cat package.json | jq -r ".dependencies | keys | .[]")
