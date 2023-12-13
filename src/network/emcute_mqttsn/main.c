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

#ifndef EMCUTE_ID
#define EMCUTE_ID ("gertrud")
#endif
#define EMCUTE_PRIO (THREAD_PRIORITY_MAIN - 1)

#define NUMOFSUBS (16U)
#define TOPIC_MAXLEN (64U)

// static char stack[THREAD_STACKSIZE_DEFAULT];
static msg_t queue[8];

static emcute_sub_t subscriptions[NUMOFSUBS];
static char topics[NUMOFSUBS][TOPIC_MAXLEN];

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

char *readFirstLine(void)
{
    const char *filePath = "~/shared/logs/BROKER_IP.txt";
    FILE *file = fopen(filePath, "r");
    if (file == NULL)
    {
        perror("Error opening file");
        puts("Error opening file");
        return NULL;
    }

    char *ipAddress = malloc(MAX_IP_LENGTH + 1); // Allocate memory for the IP address
    if (ipAddress == NULL)
    {
        perror("Memory allocation failed");
        puts("Memory allocation failed");
        fclose(file);
        return NULL;
    }

    if (fgets(ipAddress, MAX_IP_LENGTH, file) == NULL)
    {
        perror("Error reading file");
        puts("Error reading file");
        free(ipAddress);
        fclose(file);
        return NULL;
    }

    ipAddress[strcspn(ipAddress, "\n")] = 0; // Remove newline character
    fclose(file);

    return ipAddress;
}

// static void *emcute_thread(void *arg)
// {
//     (void)arg;
//     emcute_run(CONFIG_EMCUTE_DEFAULT_PORT, EMCUTE_ID);
//     return NULL;    /* should never be reached */
// }

static void on_pub(const emcute_topic_t *topic, void *data, size_t len)
{
    char *in = (char *)data;

    printf("### got publication for topic '%s' [%i] ###\n",
           topic->name, (int)topic->id);
    for (size_t i = 0; i < len; i++)
    {
        printf("%c", in[i]);
    }
    puts("");
}

// change this function work with enum it self
static unsigned get_qos(const char *str)
{
    int qos = atoi(str);
    switch (qos)
    {
    case 1:
        return EMCUTE_QOS_1;
    case 2:
        return EMCUTE_QOS_2;
    default:
        return EMCUTE_QOS_0;
    }
}

static unsigned get_qos_i(int qos)
{
    switch (qos)
    {
    case 1:
        return EMCUTE_QOS_1;
    case 2:
        return EMCUTE_QOS_2;
    default:
        return EMCUTE_QOS_0;
    }
}

static int cmd_con_i(int port, char *topic, char *message, char *ipv6_addr)
{
    sock_udp_ep_t gw = {.family = AF_INET6, .port = CONFIG_EMCUTE_DEFAULT_PORT};

    puts_append(ipv6_addr);
    // puts("error: unable to obtain topic ID");
    if (ipv6_addr_from_str((ipv6_addr_t *)&gw.addr.ipv6, ipv6_addr) == NULL)
    {
        puts_append("error parsing IPv6 address\n");
        return 1;
    }

    if (port != -1)
    {
        gw.port = port;
    }

    size_t len = strlen(message);

    if (emcute_con(&gw, true, topic, message, len, 0) != EMCUTE_OK)
    {
        printf("error: unable to connect to [%s]:%i\n", ipv6_addr, (int)gw.port);
        return 1;
    }
    printf("Successfully connected to gateway at [%s]:%i\n",
           ipv6_addr, (int)gw.port);

    return 0;
}

static int cmd_con(int argc, char **argv)
{
    sock_udp_ep_t gw = {.family = AF_INET6, .port = CONFIG_EMCUTE_DEFAULT_PORT};
    char *topic = NULL;
    char *message = NULL;
    size_t len = 0;

    if (argc < 2)
    {
        printf("usage: %s <ipv6 addr> [port] [<will topic> <will message>]\n",
               argv[0]);
        return 1;
    }

    /* parse address */
    if (ipv6_addr_from_str((ipv6_addr_t *)&gw.addr.ipv6, argv[1]) == NULL)
    {
        printf("error parsing IPv6 address\n");
        return 1;
    }

    if (argc >= 3)
    {
        gw.port = atoi(argv[2]);
    }
    if (argc >= 5)
    {
        topic = argv[3];
        message = argv[4];
        len = strlen(message);
    }

    if (emcute_con(&gw, true, topic, message, len, 0) != EMCUTE_OK)
    {
        printf("error: unable to connect to [%s]:%i\n", argv[1], (int)gw.port);
        return 1;
    }
    printf("Successfully connected to gateway at [%s]:%i\n",
           argv[1], (int)gw.port);

    return 0;
}

static int cmd_discon(int argc, char **argv)
{
    (void)argc;
    (void)argv;

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

static int cmd_pub(int argc, char **argv)
{
    emcute_topic_t t;
    unsigned flags = EMCUTE_QOS_0;

    if (argc < 3)
    {
        printf("usage: %s <topic name> <data> [QoS level]\n", argv[0]);
        return 1;
    }

    /* parse QoS level */
    if (argc >= 4)
    {
        flags |= get_qos(argv[3]);
    }

    printf("pub with topic: %s and name %s and flags 0x%02x\n", argv[1], argv[2], (int)flags);

    /* step 1: get topic id */
    t.name = argv[1];
    if (emcute_reg(&t) != EMCUTE_OK)
    {
        puts("error: unable to obtain topic ID");
        return 1;
    }

    /* step 2: publish data */
    if (emcute_pub(&t, argv[2], strlen(argv[2]), flags) != EMCUTE_OK)
    {
        printf("error: unable to publish data to topic '%s [%i]'\n",
               t.name, (int)t.id);
        return 1;
    }

    printf("Published %i bytes to topic '%s [%i]'\n",
           (int)strlen(argv[2]), t.name, t.id);

    return 0;
}

static int cmd_pub_i(int qos, char *data, char *topic)
{
    emcute_topic_t t;
    unsigned flags = EMCUTE_QOS_0;

    flags |= get_qos_i(qos);

    // printf("pub with topic: %s and name %s and flags 0x%02x\n", topic, data, (int)flags);

    /* step 1: get topic id */
    t.name = topic;
    if (emcute_reg(&t) != EMCUTE_OK)
    {
        puts("error: unable to obtain topic ID");
        return 1;
    }

    /* step 2: publish data */
    if (emcute_pub(&t, data, strlen(data), flags) != EMCUTE_OK)
    {
        printf("error: unable to publish data to topic '%s [%i]'\n",
               t.name, (int)t.id);
        return 1;
    }

    // printf("Published %i bytes to topic '%s [%i]'\n", data(int) strlen(data), t.name, t.id);

    return 0;
}

static int cmd_sub(int argc, char **argv)
{
    unsigned flags = EMCUTE_QOS_0;

    if (argc < 2)
    {
        printf("usage: %s <topic name> [QoS level]\n", argv[0]);
        return 1;
    }

    if (strlen(argv[1]) > TOPIC_MAXLEN)
    {
        puts("error: topic name exceeds maximum possible size");
        return 1;
    }
    if (argc >= 3)
    {
        flags |= get_qos(argv[2]);
    }

    /* find empty subscription slot */
    unsigned i = 0;
    for (; (i < NUMOFSUBS) && (subscriptions[i].topic.id != 0); i++)
    {
    }
    if (i == NUMOFSUBS)
    {
        puts("error: no memory to store new subscriptions");
        return 1;
    }

    subscriptions[i].cb = on_pub;
    strcpy(topics[i], argv[1]);
    subscriptions[i].topic.name = topics[i];
    if (emcute_sub(&subscriptions[i], flags) != EMCUTE_OK)
    {
        printf("error: unable to subscribe to %s\n", argv[1]);
        return 1;
    }

    printf("Now subscribed to %s\n", argv[1]);
    return 0;
}

static int cmd_unsub(int argc, char **argv)
{
    if (argc < 2)
    {
        printf("usage %s <topic name>\n", argv[0]);
        return 1;
    }

    /* find subscriptions entry */
    for (unsigned i = 0; i < NUMOFSUBS; i++)
    {
        if (subscriptions[i].topic.name &&
            (strcmp(subscriptions[i].topic.name, argv[1]) == 0))
        {
            if (emcute_unsub(&subscriptions[i]) == EMCUTE_OK)
            {
                memset(&subscriptions[i], 0, sizeof(emcute_sub_t));
                printf("Unsubscribed from '%s'\n", argv[1]);
            }
            else
            {
                printf("Unsubscription form '%s' failed\n", argv[1]);
            }
            return 0;
        }
    }

    printf("error: no subscription for topic '%s' found\n", argv[1]);
    return 1;
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

// static const shell_command_t shell_commands[] = {
//     { "con", "connect to MQTT broker", cmd_con },
//     { "discon", "disconnect from the current broker", cmd_discon },
//     { "pub", "publish something", cmd_pub },
//     { "sub", "subscribe topic", cmd_sub },
//     { "unsub", "unsubscribe from topic", cmd_unsub },
//     { "will", "register a last will", cmd_will },
//     { NULL, NULL, NULL }
// };

static char *server_ip = MQTT_BROKER_IP;

int main(void)
{
    puts_append("Publish subscriber example - Group 12 MQTT\n");
    // char *server_ip = readFirstLine();
    if (server_ip == NULL)
    {
        puts("broker ip cannot read\n");
        return -1;
    }
    puts_append(server_ip);
    msg_init_queue(queue, ARRAY_SIZE(queue));

    // /* initialize our subscription buffers */
    memset(subscriptions, 0, (NUMOFSUBS * sizeof(emcute_sub_t)));

    puts_append("Publish subscriber example for MQTT\n");
    if (cmd_con_i(1886, "temperature", "hi", server_ip))
    {
        puts_append("connection to broker is invalid\n");
        return 1;
    }

    // int counter = 1000;
    while (1)
    {
        ztimer_sleep(ZTIMER_MSEC, 1000);


        cmd_pub_i(1, "temp0", "temperature");
    }

    /* start the emcute thread */
    // thread_create(stack, sizeof(stack), EMCUTE_PRIO, 0,
    //   emcute_thread, NULL, "emcute");

    /* start shell */
    // char line_buf[SHELL_DEFAULT_BUFSIZE];
    // shell_run(shell_commands, line_buf, SHELL_DEFAULT_BUFSIZE);

    /* should be never reached */
    return 0;
}
