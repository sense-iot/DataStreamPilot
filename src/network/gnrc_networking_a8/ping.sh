#!/usr/bin/env bash

ip -6 -o addr show eth0
ping -c 4 2001:4860:4860::8888