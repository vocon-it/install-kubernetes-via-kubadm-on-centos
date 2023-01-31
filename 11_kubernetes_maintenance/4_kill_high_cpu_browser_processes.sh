#!/usr/bin/env bash

ps -ef | egrep 'chrome|firefox' | awk '{print $2" "$7}' | egrep '[0-9][0-9]:[0-9][5-9]:[0-9][0-9]' | awk '{print $1}' | while read PROCESS; do echo killing $PROCESS; kill $PROCESS; done; 

# kill miner's processes
ps -ef | egrep 'python.*idle|xmrig' | grep -v grep | awk '{print $2}' | while read PROCESS; do echo killing $PROCESS; kill $PROCESS; done;
