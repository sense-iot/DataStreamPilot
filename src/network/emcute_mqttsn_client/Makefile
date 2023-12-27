# name of your application
APPLICATION = emcute_mqttsn_client

# If no BOARD is found in the environment, use this default:
BOARD ?= iotlab-m3

CFLAGS += -Werror -Wall -Wextra -Wdouble-promotion -Wformat=2 -Wformat-security -fno-common -Wno-unused-function

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

USEMODULE += netdev_default
# USEMODULE += gnrc_netdev_default
USEMODULE += auto_init_gnrc_netif
USEMODULE += gnrc_ipv6_default
USEMODULE += emcute
USEMODULE += ztimer_msec
# USEMODULE += ztimer_sec
USEMODULE += shell
USEMODULE += lps331ap
USEMODULE += random
USEMODULE += emcute

DEVELHELP ?= 1

QUIET ?= 1

include $(RIOTBASE)/Makefile.include

include $(RIOTMAKE)/default-radio-settings.inc.mk
