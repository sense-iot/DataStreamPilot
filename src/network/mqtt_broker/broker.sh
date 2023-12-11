#!/usr/bin/env bash

ip -6 -o addr show eth0
broker_mqtts ~/A8/broker_config.conf
