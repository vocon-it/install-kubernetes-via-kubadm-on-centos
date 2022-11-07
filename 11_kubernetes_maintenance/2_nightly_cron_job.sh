#!/usr/bin/env bash

# run in the directory, where $0 is located:
DIR="$(cd $(dirname $0); pwd)" && cd "${DIR}" 

# check, if sudo is supported:
sudo echo supported > /dev/null 2>/dev/null || alias sudo=$@

# remove unused images:
sudo crictl rmi --prune

# pre-fetch container images (latest images and all images used in get-desktop): 
_PREFETCH_IMAGES=$(kubectl -n get-desktop get deploy -o yaml | egrep 'IMAGE$' -A 1 | grep value | awk '{print $2}')
sudo bash 3_pre-pull-images.sh kasmweb/desktop-deluxe:1.11.0 vocon/intellij-desktop:latest vocon/deploy-intellij-desktop:latest vocon/idle-timeout:latest $_PREFETCH_IMAGES
