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
#include <math.h>
#include "shell.h"
#include "msg.h"
#include "net/emcute.h"
#include "net/ipv6/addr.h"
#include "thread.h"
#include "ztimer.h"
#include "shell.h"
#include "mutex.h"
#include "lpsxxx.h"
#include "lpsxxx_params.h"

#define ENABLE_DEBUG 1
#include "debug.h"

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

typedef struct
{
    int16_t tempList[8];
} data_t;

static data_t data;

static lpsxxx_t lpsxxx;
// static mutex_t lps_lock = MUTEX_INIT;

#define LPSXXX_REG_RES_CONF (0x10)
#define LPSXXX_REG_CTRL_REG2 (0x21)
#define DEV_I2C (dev->params.i2c)
#define DEV_ADDR (dev->params.addr)
#define DEV_RATE (dev->params.rate)

int write_register_value(const lpsxxx_t *dev, uint16_t reg, uint8_t value)
{
    i2c_acquire(DEV_I2C);
    if (i2c_write_reg(DEV_I2C, DEV_ADDR, reg, value, 0) < 0)
    {
        i2c_release(DEV_I2C);
        return -LPSXXX_ERR_I2C;
    }
    i2c_release(DEV_I2C);

    return LPSXXX_OK; // Success
}

int temp_sensor_write_CTRL_REG2_value(const lpsxxx_t *dev, uint8_t value)
{
    return write_register_value(dev, LPSXXX_REG_CTRL_REG2, value);
}

int temp_sensor_write_res_conf(const lpsxxx_t *dev, uint8_t value)
{
    return write_register_value(dev, LPSXXX_REG_RES_CONF, value);
}

int temp_sensor_reset(void)
{
    lpsxxx_params_t paramts = {
        .i2c = lpsxxx_params[0].i2c,
        .addr = lpsxxx_params[0].addr,
        .rate = LPSXXX_RATE_7HZ};
    // .rate = lpsxxx_params[0].rate
    // LPSXXX_RATE_7HZ = 5,        /**< sample with 7Hz, default */
    //   LPSXXX_RATE_12HZ5 = 6,      /**< sample with 12.5Hz */
    //   LPSXXX_RATE_25HZ = 7

    if (lpsxxx_init(&lpsxxx, &paramts) != LPSXXX_OK)
    {
        puts("Sensor initialization failed");
        return 0;
    }

    // 7       6543    2          1      0
    // BOOT RESERVED SWRESET AUTO_ZERO ONE_SHOT
    //  1      0000   1      0            0
    // 44
    if (temp_sensor_write_CTRL_REG2_value(&lpsxxx, 0x44) != LPSXXX_OK)
    {
        puts("Sensor reset failed");
        return 0;
    }

    ztimer_sleep(ZTIMER_MSEC, 5000);

    // 0x40 -- 01000000
    // AVGT2 AVGT1 AVGT0 100 --  Nr. internal average : 16
    if (temp_sensor_write_res_conf(&lpsxxx, 0x40) != LPSXXX_OK)
    {
        puts("Sensor enable failed");
        return 0;
    }

    if (lpsxxx_enable(&lpsxxx) != LPSXXX_OK)
    {
        puts("Sensor enable failed");
        return 0;
    }

    ztimer_sleep(ZTIMER_MSEC, 1000);
    return 1;
}

float generate_normal_random(float stddev)
{
    float M_PI = 3.1415926535;

    // Box-Muller transform to generate random numbers with normal distribution
    float u1 = rand() / (float)RAND_MAX;
    float u2 = rand() / (float)RAND_MAX;
    float z = sqrt(-2 * log(u1)) * cos(2 * M_PI * u2);

    return stddev * z;
}

float add_noise(float stddev)
{
    int num;
    float noise_val = 0;

    num = rand() % 100 + 1; // use rand() function to get the random number
    if (num >= 50)
    {
        // Generate a random number with normal distribution based on a stddev
        noise_val = generate_normal_random(stddev);
    }
    return noise_val;
}


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

    if (temp_sensor_reset() == 0)
    {
        puts("Sensor failed");
        return 1;
    }

    int array_length = 0;

    while (1)
    {

        int16_t temp = 0;
        if (lpsxxx_read_temp(&lpsxxx, &temp) == LPSXXX_OK)
        {
            // DEBUG_PRINT("Temperature: %i.%u°C\n", (temp / 100), (temp % 100));

            int16_t temp_n_noise = temp + (int16_t)add_noise(789.2);
            DEBUG_PRINT("Temperature with noise: %i.%u°C\n", (temp_n_noise / 100), (temp_n_noise % 100));
            if (array_length < 7)
            {
                data.tempList[array_length++] = temp_n_noise;
            }
            else
            {
                data.tempList[array_length++] = temp_n_noise;
                int32_t sum = 0;
                int numElements = array_length;
                // printf("No of ele: %i\n", numElements);
                for (int i = 0; i < numElements; i++)
                {
                    sum += (int32_t)data.tempList[i];
                    // printf("Temp List: %i.%u°C\n", (data.tempList[i] / 100), (data.tempList[i] % 100));
                }

                // printf("Sum: %li\n", sum);

                // avg_temp = sum / numElements;

                double avg_temp = (double)sum / numElements;

                // Round to the nearest integer
                int16_t rounded_avg_temp = (int16_t)round(avg_temp);

                char temp_str[10];

                sprintf(temp_str, "%i", rounded_avg_temp);
                printf("Temp Str: %s\n", temp_str);
                cmd_pub_simple(temp_str);

                for (int i = 0; i < array_length - 1; ++i)
                {
                    data.tempList[i] = data.tempList[i + 1];
                }
                array_length--;
            }
        }
        ztimer_sleep(ZTIMER_MSEC, 1000);
    }

    cmd_discon_simple();
    return 0;
}
