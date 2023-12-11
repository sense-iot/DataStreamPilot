#!/usr/bin/env bash

ip -6 -o addr show eth0
iotlab_flash A8/${GNRC_NETWORKING_EXE_NAME}.elf
ping 2001:4860:4860::8888