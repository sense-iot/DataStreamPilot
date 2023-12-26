# name of your application
APPLICATION = emcute_mqttsn_client

# If no BOARD is found in the environment, use this default:
BOARD ?= iotlab-m3

CFLAGS += -Werror -Wall -Wextra -Wdouble-promotion -Wformat=2 -Wformat-security -fno-common -Wno-unused-function

MQTT_BROKER_IP=${BROKER_IP}
CFLAGS += -DMQTT_BROKER_IP='"${MQTT_BROKER_IP}"'

# This has to be the absolute path to the RIOT base directory:
RIOTBASE ?= $(CURDIR)/../../../external/RIOT

# Include packages that pull up and auto-init the link layer.
# NOTE: 6LoWPAN will be included if IEEE802.15.4 devices are present
USEMODULE += gnrc_netdev_default
USEMODULE += auto_init_gnrc_netif
#USEMODULE += gnrc_sock_udp
# Specify the mandatory networking modules for IPv6
USEMODULE += gnrc_ipv6_default
# Include MQTT-SN
USEMODULE += emcute
# Add also the shell, some shell commands
# USEMODULE += shell
# USEMODULE += shell_commands
#USEMODULE += ps
# For testing we also include the ping command and some stats
#USEMODULE += gnrc_icmpv6_echo
# Optimize network stack to for use with a single network interface
# USEMODULE += gnrc_netif_single

#USEMODULE += gnrc_sixlowpan_router_default

# USEMODULE += ztimer_usec
USEMODULE += ztimer_msec
USEMODULE += ztimer_sec
# USEMODULE += ztimer_no_periph_rtt
# SEMODULE += gnrc_icmpv6_error
# USEMODULE += gnrc_icmpv6_echo

USEMODULE += shell
# USEMODULE += gnrc_rpl
# USEMODULE += auto_init_gnrc_rpl
# USEMODULE += gnrc_ipv6_router_default
# USEMODULE += gnrc_udp

USEMODULE += lps331ap
USEMODULE += random

# Allow for env-var-based override of the nodes name (EMCUTE_ID)
ifneq (,$(EMCUTE_ID))
  CFLAGS += -DEMCUTE_ID=\"$(EMCUTE_ID)\"
endif

ifneq (,$(CLIENT_TOPIC))
  CFLAGS += -DCLIENT_TOPIC=\"$(CLIENT_TOPIC)\"
endif

# Comment this out to disable code in RIOT that does safety checking
# which is not needed in a production environment but helps in the
# development process:
DEVELHELP ?= 1

# Comment this out to join RPL DODAGs even if DIOs do not contain
# DODAG Configuration Options (see the doc for more info)
# CFLAGS += -DCONFIG_GNRC_RPL_DODAG_CONF_OPTIONAL_ON_JOIN

# Change this to 0 show compiler invocation lines by default:
QUIET ?= 1

include $(RIOTBASE)/Makefile.include

# Set a custom channel if needed
include $(RIOTMAKE)/default-radio-settings.inc.mk
