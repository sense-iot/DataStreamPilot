APPLICATION = compute_engine

BOARD ?= iotlab-m3

RIOTBASE ?= $(CURDIR)/../../external/RIOT

CFLAGS += -Werror -Wall -Wextra -Wdouble-promotion -Wformat=2 -Wformat-security -fno-common -Wno-unused-function

USEMODULE += ztimer_usec
USEMODULE += ztimer_msec
USEMODULE += ztimer_sec
USEMODULE += ztimer_no_periph_rtt
USEMODULE += lps331ap
USEMODULE += xtimer
USEMODULE += netdev_default
USEMODULE += auto_init_gnrc_netif
USEMODULE += gnrc_ipv6_default
USEMODULE += sock_udp
USEMODULE += gcoap
USEMODULE += gnrc_icmpv6_error
USEMODULE += gnrc_icmpv6_echo
USEMODULE += gnrc_icmpv6_error
USEMODULE += gnrc_ipv6_router_default
USEMODULE += gnrc_rpl
USEMODULE += auto_init_gnrc_rpl
USEMODULE += gnrc_icmpv6_error
USEMODULE += gnrc_ipv6_router_default
USEMODULE += gnrc_udp
USEMODULE += shell_commands
USEMODULE += netstats_l2
USEMODULE += netstats_ipv6
USEMODULE += netstats_rpl

# use GNRC by default
LWIP_IPV4 ?= 0
LWIP_IPV6 ?= 0

CFLAGS += -Wno-unused-but-set-variable -Wno-unused-parameter

ifeq (,$(filter 1, $(LWIP_IPV4) $(LWIP_IPV6)))
  USEMODULE += auto_init_gnrc_netif
  # Specify the mandatory networking modules
  USEMODULE += gnrc_ipv6_default
  # Additional networking modules that can be dropped if not needed
  USEMODULE += gnrc_icmpv6_echo
else
  # USEMODULE += lwip_netdev

  ifeq (1,$(LWIP_IPV4))
    # USEMODULE += ipv4_addr

    USEMODULE += lwip_arp
    USEMODULE += lwip_ipv4
    USEMODULE += lwip_dhcp_auto
    CFLAGS += -DETHARP_SUPPORT_STATIC_ENTRIES=1
  endif

  ifeq (1,$(LWIP_IPV6))
    USEMODULE += ipv6_addr

    USEMODULE += lwip_ipv6
    USEMODULE += lwip_ipv6_autoconfig
  endif
endif

USEMODULE += gcoap
USEMODULE += od
USEMODULE += fmt
USEMODULE += shell
USEMODULE += netstats_ipv6
USEMODULE += ps
USEMODULE += random

# Change this to 0 show compiler invocation lines by default:
QUIET ?= 1

# Instead of simulating an Ethernet connection, we can also simulate
# an IEEE 802.15.4 radio using ZEP
USE_ZEP ?= 0
# set the ZEP port for native
ZEP_PORT_BASE ?= 17754
ifeq (1,$(USE_ZEP))
  TERMFLAGS += -z [::1]:$(ZEP_PORT_BASE)
  USEMODULE += socket_zep

  ifneq (,$(ZEP_MAC))
    TERMFLAGS += --eui64=$(ZEP_MAC)
  endif
endif

include $(RIOTBASE)/Makefile.include
ifndef CONFIG_KCONFIG_MODULE_GCOAP
GCOAP_RESEND_BUFS_MAX ?= 2
CFLAGS += -DCONFIG_GCOAP_RESEND_BUFS_MAX=$(GCOAP_RESEND_BUFS_MAX)
endif
include $(RIOTMAKE)/default-radio-settings.inc.mk
