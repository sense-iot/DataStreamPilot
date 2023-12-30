#!/usr/bin/env bash


iotlab_flash A8/compute_engine_3_a8.elf
ip -6 -o addr show eth0
# miniterm.py /dev/ttyA8_M3 500000 -e
