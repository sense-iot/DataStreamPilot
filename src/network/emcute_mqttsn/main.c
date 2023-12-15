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

static void *emcute_thread(void *arg)
{
    (void)arg;
    emcute_run(CONFIG_EMCUTE_DEFAULT_PORT, EMCUTE_ID);
    return NULL; /* should never be reached */
}

char *sensor1_data = NULL;
char *sensor2_data = NULL;
char *sensor3_data = NULL;
int count = 0;
static mutex_t cb_lock = MUTEX_INIT;

static void on_pub_3(const emcute_topic_t *topic, void *data, size_t len)
{
    char *in = (char *)data;

    if (count >= 3) {
        ztimer_sleep(ZTIMER_MSEC, 97);
    }

    if (strcmp(topic->name, "sens3_temperature") != 0)
    {
        ztimer_sleep(ZTIMER_MSEC, 120);
        return;
    }

    printf("### got publication for topic '%s' [%i] ###\n", topic->name, (int)topic->id);
    printf("count : %d - Data : %s \n", count, in);

    if (sensor3_data == NULL)
    {
        sensor3_data = malloc(len + 1);
        strncpy(sensor3_data, in, len);
        sensor3_data[len] = '\0';
    } else {
        free(sensor3_data);
        sensor3_data = malloc(len + 1);
        strncpy(sensor3_data, in, len);
        sensor3_data[len] = '\0';
    }

    mutex_lock(&cb_lock);
    count++;
    mutex_unlock(&cb_lock);
}

static void on_pub_1(const emcute_topic_t *topic, void *data, size_t len)
{
    char *in = (char *)data;

    if (strcmp(topic->name, "sens1_temperature") != 0)
    {
        ztimer_sleep(ZTIMER_MSEC, 80);
        return;
    }

    printf("### got publication for topic '%s' [%i] ###\n", topic->name, (int)topic->id);

    if (count >= 3)
    {
        printf("===============================================\n\n");
        count = 0;
        if (sensor1_data != NULL)
        {
            printf("sensor 1 : %s \n", sensor1_data);
        }
        if (sensor2_data != NULL)
        {
            printf("sensor 2 : %s \n", sensor2_data);
        }
        if (sensor3_data != NULL)
        {
            printf("sensor 3 : %s \n", sensor3_data);
        }
        printf("===============================================\n\n");
    }

    if (sensor1_data == NULL)
    {
        sensor1_data = malloc(len + 1);
        strcpy(sensor1_data, in);
        strncpy(sensor1_data, in, len);
        sensor1_data[len] = '\0';
    }
    else
    {
        free(sensor1_data);
        sensor1_data = malloc(len + 1);
        strncpy(sensor1_data, in, len);
        sensor1_data[len] = '\0';
    }

    mutex_lock(&cb_lock);
    count++;
    mutex_unlock(&cb_lock);
}

static void on_pub_2(const emcute_topic_t *topic, void *data, size_t len)
{
    char *in = (char *)data;

    if (count >= 3)
    {
        ztimer_sleep(ZTIMER_MSEC, 135);
    }

    if (strcmp(topic->name, "sens2_temperature") != 0)
    {
        ztimer_sleep(ZTIMER_MSEC, 113);
        return;
    }
    printf("### got publication for topic '%s' [%i] ###\n", topic->name, (int)topic->id);
    printf("count : %d - Data : %s \n", count, in);

    if (sensor2_data == NULL)
    {
        sensor2_data = malloc(len + 1);
        strncpy(sensor2_data, in, len);
        sensor2_data[len] = '\0'; 
    }
    else
    {
        free(sensor2_data);
        sensor2_data = malloc(len + 1);
        strncpy(sensor2_data, in, len);
        sensor2_data[len] = '\0';
    }

    mutex_lock(&cb_lock);
    count++;
    mutex_unlock(&cb_lock);
}

static void on_pub(const emcute_topic_t *topic, void *data, size_t len)
{
    char *in = (char *)data;

    printf("### got publication for topic '%s' [%i] ###\n", topic->name, (int)topic->id);
    printf("count : %d - Data : %s ", count, in);

    if (count >= 3) {
        count = 0;
        if (sensor1_data != NULL) {
            printf("sensor 1 : %s ", sensor1_data);
        }
         if (sensor2_data != NULL) {
        printf("sensor 2 : %s ", sensor2_data);
         }
          if (sensor3_data   != NULL) {
        printf("sensor 3 : %s ", sensor3_data);
          }
        if (sensor1_data != NULL) {
            free(sensor1_data);
            sensor1_data = NULL;
        }
        if (sensor2_data != NULL) {
            free(sensor2_data);
            sensor2_data = NULL;
        }
        if (sensor3_data != NULL) {
            free(sensor3_data);
            sensor3_data = NULL;
        }
        printf("\n");
    }

    if (strcmp(topic->name, "sens1_temperature") == 0)
    {
        if (sensor1_data == NULL) {
            sensor1_data = malloc(strlen(in) + 1);
            strcpy(sensor1_data, in);
        }

    }
    else if (strcmp(topic->name, "sens2_temperature") == 0)
    {
        if (sensor2_data == NULL) {
            sensor2_data = malloc(strlen(in) + 1);
            strcpy(sensor2_data, in);
        }
    }
    else
    {
        if (sensor3_data == NULL) {
            sensor3_data = malloc(strlen(in) + 1);
            strcpy(sensor3_data, in);
        }
    }
    count++;
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

    // if (argc >= 3)
    // {
    //     gw.port = atoi(argv[2]);
    // }
    // if (argc >= 5)
    // {
    //     topic = argv[3];
    //     message = argv[4];
    //     len = strlen(message);
    // }
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

static int cmd_sub_1(int argc, char **argv, emcute_cb_t cb)
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

    subscriptions[i].cb = cb;
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

static int cmd_sub_2(int argc, char **argv)
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

    subscriptions[i].cb = on_pub_2;
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

static int cmd_sub_3(int argc, char **argv)
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

    subscriptions[i].cb = on_pub_3;
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

static const shell_command_t shell_commands[] = {
    {"con", "connect to MQTT broker", cmd_con},
    {"discon", "disconnect from the current broker", cmd_discon},
    {"pub", "publish something", cmd_pub},
    {"sub", "subscribe topic", cmd_sub},
    {"unsub", "unsubscribe from topic", cmd_unsub},
    {"will", "register a last will", cmd_will},
    {NULL, NULL, NULL}};

// static char *server_ip = MQTT_BROKER_IP;



static char *server_ip = MQTT_BROKER_IP;

int main(void)
{
    printf("Publish subscriber example - Group 12 MQTT\n");
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
        // return 0;
    }
    printf("connection okay\n");

    char *unsub_message[2];
    unsub_message[0] = "sub";
    cmd_con_count = 2;

    unsub_message[1] = "sens1_temperature";
    cmd_unsub(cmd_con_count, unsub_message);
    unsub_message[1] = "sens2_temperature";
    cmd_unsub(cmd_con_count, unsub_message);
    unsub_message[1] = "sens3_temperature";
    cmd_unsub(cmd_con_count, unsub_message);

    char *sub_message[2];
    sub_message[0] = "sub";
    cmd_con_count = 2;

    sub_message[1] = "sens1_temperature";
    cmd_sub_1(cmd_con_count, sub_message, on_pub_1);
    sub_message[1] = "sens2_temperature";
    cmd_sub_1(cmd_con_count, sub_message, on_pub_2);
    sub_message[1] = "sens3_temperature";
    cmd_sub_1(cmd_con_count, sub_message, on_pub_3);

    while (1)
    {
        ztimer_sleep(ZTIMER_MSEC, 1000);
    }

    char line_buf[SHELL_DEFAULT_BUFSIZE];
    shell_run(shell_commands, line_buf, SHELL_DEFAULT_BUFSIZE);

    free(sensor1_data);
    free(sensor2_data);
    free(sensor3_data);
    return 0;
}
