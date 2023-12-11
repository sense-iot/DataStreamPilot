#!/usr/bin/env bash

mosquitto_pub -h 2001:660:5307:3000::67 -p 1886 -t test/riot -m "$1"