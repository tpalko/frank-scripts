#!/bin/bash

if [[ -f /usr/local/bin/monfix ]]; then 
  rm /usr/local/bin/monfix
fi 

ln -svf $(pwd)/monfix.sh /usr/local/bin/monfix
chmod +x /usr/local/bin/monfix
