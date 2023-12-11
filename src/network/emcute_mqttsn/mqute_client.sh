#!/usr/bin/env bash


iotlab_flash A8/emcute_mqttsn.elf
ip -6 -o addr show eth0
echo "con 2001:660:5307:3000::68 1885"
echo "sub test/riot"
miniterm.py /dev/ttyA8_M3 500000 -e
