#!/usr/bin/env bash


iotlab_flash A8/emcute_mqttsn_client_SENSOR_1.elf
ip -6 -o addr show eth0
# miniterm.py /dev/ttyA8_M3 500000 -e
