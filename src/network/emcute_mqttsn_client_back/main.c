/*
 * Copyright (C) 2015 Freie Universität Berlin
 *
 * This file is subject to the terms and conditions of the GNU Lesser
 * General Public License v2.1. See the file LICENSE in the top level
 * directory for more details.
 */

/**
 * @ingroup     examples
 * @{
 *
 * @file
 * @brief       Example application for demonstrating RIOT's MQTT-SN library
 *              emCute
 *
 * @author      Hauke Petersen <hauke.petersen@fu-berlin.de>
 *
 * @}
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "shell.h"
#include "msg.h"
#include "net/emcute.h"
#include "net/ipv6/addr.h"
#include "thread.h"
#include "ztimer.h"
#include "shell.h"
#include "mutex.h"

#ifndef EMCUTE_ID
#define EMCUTE_ID ("gertrud")
#endif
#define EMCUTE_PRIO (THREAD_PRIORITY_MAIN - 1)

#define NUMOFSUBS (16U)
#define TOPIC_MAXLEN (64U)

static char stack[THREAD_STACKSIZE_DEFAULT];
static msg_t queue[8];

static emcute_sub_t subscriptions[NUMOFSUBS];

#define MAX_IP_LENGTH 46 // Maximum length for an IPv6 address

void puts_append(const char *data)
{
    // File path
    const char *filepath = "mqtt_client.log";

    // Open the file in append mode
    FILE *file = fopen(filepath, "a");
    if (file == NULL)
    {
        return;
    }

    // Write data to the file
    if (fputs(data, file) == EOF)
    {
        perror("Error writing to file");
    }

    // Close the file
    fclose(file);
}

static void *emcute_thread(void *arg)
{
    (void)arg;
    emcute_run(CONFIG_EMCUTE_DEFAULT_PORT, EMCUTE_ID);
    return NULL; /* should never be reached */
}

static int cmd_con(int argc, char **argv)
{
    sock_udp_ep_t gw = {.family = AF_INET6, .port = 1885U};
    char *topic = NULL;
    char *message = NULL;
    size_t len = 0;

    printf("Starting connection inside\n");

    if (argc < 2)
    {
        printf("usage: %s <ipv6 addr> [port] [<will topic> <will message>]\n",
               argv[0]);
        return 1;
    }

    /* parse address */
    printf("checking ip address\n");
    printf("checking ip address: %s\n", argv[1]);
    if (ipv6_addr_from_str((ipv6_addr_t *)&gw.addr.ipv6, argv[1]) == NULL)
    {
        printf("error parsing IPv6 address\n");
        return 1;
    }

    printf("ip address okay\n");

    printf("starting mqtt con\n");
    if (emcute_con(&gw, true, topic, message, len, 0) != EMCUTE_OK)
    {
        printf("error: unable to connect to [%s]:%i\n", argv[1], (int)gw.port);
        return 1;
    }
    printf("Successfully connected to gateway at [%s]:%i\n",
           argv[1], (int)gw.port);

    return 0;
}

static int cmd_discon_simple(void)
{
    int res = emcute_discon();
    if (res == EMCUTE_NOGW)
    {
        puts("error: not connected to any broker");
        return 1;
    }
    else if (res != EMCUTE_OK)
    {
        puts("error: unable to disconnect");
        return 1;
    }
    puts("Disconnect successful");
    return 0;
}

static int cmd_will(int argc, char **argv)
{
    if (argc < 3)
    {
        printf("usage %s <will topic name> <will message content>\n", argv[0]);
        return 1;
    }

    if (emcute_willupd_topic(argv[1], 0) != EMCUTE_OK)
    {
        puts("error: unable to update the last will topic");
        return 1;
    }
    if (emcute_willupd_msg(argv[2], strlen(argv[2])) != EMCUTE_OK)
    {
        puts("error: unable to update the last will message");
        return 1;
    }

    puts("Successfully updated last will topic and message");
    return 0;
}

static char *server_ip = MQTT_BROKER_IP;
static char *my_topic = CLIENT_TOPIC;

static int cmd_pub_simple(char *data)
{
    emcute_topic_t t;
    unsigned flags = EMCUTE_QOS_0;

    t.name = my_topic;
    if (emcute_reg(&t) != EMCUTE_OK)
    {
        // printf("error: unable to obtain topic ID : %s\n", my_topic);
        return 1;
    }

    // printf("pub with topic: %s and name %s and flags 0x%02x\n", my_topic, data, (int)flags);

    /* step 2: publish data */
    if (emcute_pub(&t, data, strlen(data), flags) != EMCUTE_OK)
    {
        printf("Failed\n");
        return 1;
    }
    return 0;
}


void initizlize_mqtt_client(void) {
    msg_init_queue(queue, ARRAY_SIZE(queue));
    memset(subscriptions, 0, (NUMOFSUBS * sizeof(emcute_sub_t)));
    printf("memset okay\n");

    char *cmd_con_m[3];
    cmd_con_m[0] = "con";
    cmd_con_m[1] = server_ip;
    cmd_con_m[2] = "1885";
    int cmd_con_count = 3;

    printf("char arguments okay\n");

    thread_create(stack, sizeof(stack), EMCUTE_PRIO, 0,
                  emcute_thread, NULL, "emcute");

    printf("Starting connection\n");
    if (cmd_con(cmd_con_count, cmd_con_m))
    {
        printf("broker connection failed\n");
    }
    printf("connection okay\n");

    char *will_m[3];
    will_m[0] = "will";
    will_m[1] = "dead_sensors";
    will_m[2] = "I am dead";
    int will_m_count = 3;

    if (cmd_will(will_m_count, will_m))
    {
        printf("Last will failed\n");
    }
    printf("last will okay\n");
}

int main(void)
{
    printf("Publish subscriber example - Group 12 MQTT\n");

    initizlize_mqtt_client();

    while (1)
    {
        ztimer_sleep(ZTIMER_MSEC, 1000);

        if (cmd_pub_simple("mydata"))
        {
            ztimer_sleep(ZTIMER_MSEC, 300);
            continue;
        }
    }

    cmd_discon_simple();
    return 0;
}
