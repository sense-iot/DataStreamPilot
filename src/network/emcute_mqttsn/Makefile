# name of your application
APPLICATION = emcute_mqttsn

# If no BOARD is found in the environment, use this default:
BOARD ?= iotlab-m3

CFLAGS += -Werror -Wall -Wextra -Wdouble-promotion -Wformat=2 -Wformat-security -fno-common -Wno-unused-function -Wno-unused-variable -Wno-unused-but-set-variable -Wno-unused-parameter


MQTT_BROKER_IP=${BROKER_IP}
CFLAGS += -DMQTT_BROKER_IP='"${MQTT_BROKER_IP}"'

ifneq (,$(EMCUTE_ID))
  CFLAGS += -DEMCUTE_ID=\"$(EMCUTE_ID)\"
endif

ifneq (,$(CLIENT_TOPIC))
  CFLAGS += -DCLIENT_TOPIC=\"$(CLIENT_TOPIC)\"
endif

# This has to be the absolute path to the RIOT base directory:
RIOTBASE ?= $(CURDIR)/../../../external/RIOT

# Include packages that pull up and auto-init the link layer.
USEMODULE += netdev_default
USEMODULE += auto_init_gnrc_netif
USEMODULE += gnrc_ipv6_default
USEMODULE += emcute
USEMODULE += ztimer_msec
USEMODULE += shell
# USEMODULE += shell_cmds_default
# USEMODULE += ps


DEVELHELP ?= 1

QUIET ?= 1

include $(RIOTBASE)/Makefile.include

include $(RIOTMAKE)/default-radio-settings.inc.mk
