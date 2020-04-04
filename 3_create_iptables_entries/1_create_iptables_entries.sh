#!/bin/sh

if [ "$#" == "0" ]; then
  MY_IP=$(echo $SSH_CLIENT | awk '{ print $1}')
  ADDIP="$MY_IP ganesh.vocon-it.com vocon-home.mooo.com"
else
  ADDIP="$@"
fi

# run _xxx.sh:
sudo $(cd $(dirname $0); pwd)/_$(basename $0) $ADDIP
