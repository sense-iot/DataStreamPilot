APPLICATION = paho-mqtt

# If no BOARD is found in the environment, use this default:
BOARD ?= iotlab-m3

# This has to be the absolute path to the RIOT base directory:
RIOTBASE ?= $(CURDIR)/../../../external/RIOT

# Comment this out to disable code in RIOT that does safety checking
# which is not needed in a production environment but helps in the
# development process:
DEVELHELP ?= 1

# Change this to 0 show compiler invocation lines by default:
QUIET ?= 1

WIFI_SSID ?= "group12_ssid"
WIFI_PASS ?= "group12_secure_123"

MQTT_BROKER_IP=${BROKER_IP}
CFLAGS += -DMQTT_BROKER_IP='"${MQTT_BROKER_IP}"'

# Optionally include remoteDNS support. This includes resolution of names at an
# upstream DNS server and the handling of RDNSS options in Router Advertisements
# to auto-configure that upstream DNS server.
# USEMODULE += sock_dns              # include DNS client
# USEMODULE += gnrc_ipv6_nib_dns     # include RDNSS option handling

ifneq (,$(DEFAULT_MQTT_CLIENT_ID))
  CFLAGS += -DDEFAULT_MQTT_CLIENT_ID=\"$(DEFAULT_MQTT_CLIENT_ID)\"
endif
ifneq (,$(DEFAULT_MQTT_USER))
  CFLAGS += -DDEFAULT_MQTT_USER=\"$(DEFAULT_MQTT_USER)\"
endif
ifneq (,$(DEFAULT_MQTT_PWD))
  CFLAGS += -DDEFAULT_MQTT_PWD=\"$(DEFAULT_MQTT_PWD)\"
endif

USEMODULE += shell_cmds_default
USEMODULE += ps
USEMODULE += netdev_default
USEPKG += paho-mqtt

USEMODULE += auto_init_gnrc_netif
USEMODULE += gnrc_icmpv6_error
USEMODULE += netstats_ipv6

# paho-mqtt depends on TCP support, choose which stacks you want
GNRC_IPV6 ?= 1
LWIP_IPV4 ?= 0
LWIP_IPV6 ?= 0

include Makefile.lwip
include Makefile.gnrc

USEMODULE += sock_async_event
USEMODULE += sock_ip
USEMODULE += sock_udp
USEMODULE += sock_tcp

USEMODULE += ztimer_usec
USEMODULE += ztimer_msec
USEMODULE += ztimer_sec
USEMODULE += ztimer_no_periph_rtt

####

ifneq (,$(EMCUTE_ID))
  CFLAGS += -DEMCUTE_ID=\"$(EMCUTE_ID)\"
endif

ifneq (,$(CLIENT_TOPIC))
  CFLAGS += -DCLIENT_TOPIC=\"$(CLIENT_TOPIC)\"
endif


include $(RIOTBASE)/Makefile.include

ifneq (,$(filter arch_esp,$(FEATURES_USED)))
  CFLAGS += -DWIFI_SSID=\"$(WIFI_SSID)\"
  CFLAGS += -DWIFI_PASS=\"$(WIFI_PASS)\"
endif

# Set a custom channel if needed
include $(RIOTMAKE)/default-radio-settings.inc.mk