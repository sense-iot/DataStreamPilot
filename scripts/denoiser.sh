#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

my_arch=iotlab-a8-m3

build_wireless_firmware ${DENOISER_HOME} ${DENOISER_EXE_NAME} ${my_arch}
build_status=$?
if [ $build_status -ne 0 ]; then
  exit $build_status
fi

if [ -n "$IOT_LAB_FRONTEND_FQDN" ]; then
  cp ${DENOISER_HOME}/bin/${my_arch}/${DENOISER_EXE_NAME}.elf ${SENSE_FIRMWARE_HOME}
  cp ${DENOISER_HOME}/bin/${my_arch}/${DENOISER_EXE_NAME}.elf ${SENSE_HOME}/release/${DENOISER_EXE_NAME}.elf

  if [ "$my_arch" = "iotlab-m3" ]; then
      echo "Architecture is iotlab-m3."
      echo "Flashing new firmware for ${my_arch} node : ${DENOISER_NODE}"
      flash_firmware ${DENOISER_EXE_NAME} ${DENOISER_NODE}
      echo "nc m3-${DENOISER_NODE} 20000"
  elif [ "$my_arch" = "iotlab-a8-m3" ]; then
      cp ${DENOISER_HOME}/bin/${my_arch}/${DENOISER_EXE_NAME}.elf ~/A8/${DENOISER_EXE_NAME}.elf
      echo "Architecture is iotlab-a8-m3."
      ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/nullw root@node-a8-${DENOISER_NODE} 'bash -s' <${SENSE_HOME}/src/network/denoiser/ssh_denoiser.sh
      echo "ssh root@node-a8-${DENOISER_NODE}"
  else
      echo "Architecture is something else."
  fi
fi

