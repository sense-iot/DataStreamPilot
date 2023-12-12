#!/usr/bin/env bash

mosquitto_pub -h fe80::fadc:7aff:fe01:95f8 -p 1886 -t test/riot -m "$1"