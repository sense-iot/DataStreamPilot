#!/usr/bin/env bash

iotlab_flash A8/gnrc_border_router_a8.elf
cd ~/A8/riot/RIOT/dist/tools/uhcpd
make all
cd ../ethos
make all
./start_network.sh /dev/ttyA8_M3 tap9 2001:660:5307:313a::/64 500000