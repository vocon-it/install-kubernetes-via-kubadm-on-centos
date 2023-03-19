#!/usr/bin/env bash

ps -ef | egrep 'chrome|firefox' | awk '{print $2" "$7}' | egrep '[0-9][0-9]:[0-9][5-9]:[0-9][0-9]' | awk '{print $1}' | while read PROCESS; do echo killing $PROCESS; kill $PROCESS; done; 

# kill miner's processes
ps -ef | egrep 'python.*idle|xmrig' | grep -v grep | awk '{print $2}' | while read PROCESS; do echo killing $PROCESS; kill $PROCESS; done;

# Detect high CPU and kill the Process with highest CPU found:
NODE_CPU_PERCENT=$(kubectl top nodes | grep $(hostname) | awk '{print $3}' | sed 's/%//')
[ "${CPU_PERCENT}" -ge 90 ] && top -n 1 | head -8  | tail -1 | awk '{print $1}' | while read PROCESS; do kill -9 $PROCESS; done
