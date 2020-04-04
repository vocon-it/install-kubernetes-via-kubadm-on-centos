#!/usr/bin/env bash

set -euxo pipefail

sudo kubeadm reset --force
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -X

# TODO: test/improve create iptables
bash $(cd $(dirname $0); pwd)/../3_create_iptables_entries/1_create_iptables_entries.sh

