/*
 * Copyright (C) 2019 Javier FILEIV <javier.fileiv@gmail.com>
 *
 * This file is subject to the terms and conditions of the GNU Lesser
 * General Public License v2.1. See the file LICENSE in the top level
 * directory for more details.
 */

/**
 * @ingroup     examples
 * @{
 *
 * @file        main.c
 * @brief       Example using MQTT Paho package from RIOT
 *
 * @author      Javier FILEIV <javier.fileiv@gmail.com>
 *
 * @}
 */

#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>
#include "timex.h"
#include "ztimer.h"
#include "shell.h"
#include "thread.h"
#include "mutex.h"
#include "paho_mqtt.h"
#include "MQTTClient.h"
#include "lpsxxx.h"
#include "lpsxxx_params.h"

#define ENABLE_DEBUG 0
#include "debug.h"

#define MAIN_QUEUE_SIZE     (8)
static msg_t _main_msg_queue[MAIN_QUEUE_SIZE];

#define BUF_SIZE                        1024
#define MQTT_VERSION_v311               4       /* MQTT v3.1.1 version is 4 */
#define COMMAND_TIMEOUT_MS              4000

#ifndef DEFAULT_MQTT_CLIENT_ID
#define DEFAULT_MQTT_CLIENT_ID EMCUTE_ID
#endif

#ifndef DEFAULT_MQTT_USER
#define DEFAULT_MQTT_USER               ""
#endif

#ifndef DEFAULT_MQTT_PWD
#define DEFAULT_MQTT_PWD                ""
#endif

/**
 * @brief Default MQTT port
 */
#define DEFAULT_MQTT_PORT               1885

/**
 * @brief Keepalive timeout in seconds
 */
#define DEFAULT_KEEPALIVE_SEC           10

#ifndef MAX_LEN_TOPIC
#define MAX_LEN_TOPIC                   1
#endif

#ifndef MAX_TOPICS
#define MAX_TOPICS                      1
#endif

#define IS_CLEAN_SESSION                1
#define IS_RETAINED_MSG                 0

static MQTTClient client;
static Network network;
static int topic_cnt = 0;
static char _topic_to_subscribe[MAX_TOPICS][MAX_LEN_TOPIC];

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

    ztimer_sleep(ZTIMER_MSEC, 1000);
    if (lpsxxx_enable(&lpsxxx) != LPSXXX_OK)
    {
        puts("Sensor enable failed");
        return 0;
    }

    ztimer_sleep(ZTIMER_MSEC, 1000);
    return 1;
}

static unsigned get_qos(const char *str)
{
    int qos = atoi(str);

    switch (qos) {
    case 1:     return QOS1;
    case 2:     return QOS2;
    default:    return QOS0;
    }
}

static void _on_msg_received(MessageData *data)
{
    printf("paho_mqtt_example: message received on topic"
           " %.*s: %.*s\n",
           (int)data->topicName->lenstring.len,
           data->topicName->lenstring.data, (int)data->message->payloadlen,
           (char *)data->message->payload);
}

static int _cmd_discon(int argc, char **argv)
{
    (void)argc;
    (void)argv;

    topic_cnt = 0;
    int res = MQTTDisconnect(&client);
    if (res < 0) {
        printf("mqtt_example: Unable to disconnect\n");
    }
    else {
        printf("mqtt_example: Disconnect successful\n");
    }

    NetworkDisconnect(&network);
    return res;
}

static int _cmd_con(int argc, char **argv)
{
    if (argc < 2) {
        printf(
            "usage: %s <brokerip addr> [port] [clientID] [user] [password] "
            "[keepalivetime]\n",
            argv[0]);
        return 1;
    }

    char *remote_ip = argv[1];

    int ret = -1;

    /* ensure client isn't connected in case of a new connection */
    if (client.isconnected) {
        printf("mqtt_example: client already connected, disconnecting it\n");
        MQTTDisconnect(&client);
        NetworkDisconnect(&network);
    }

    int port = DEFAULT_MQTT_PORT;
    if (argc > 2) {
        port = atoi(argv[2]);
    }

    MQTTPacket_connectData data = MQTTPacket_connectData_initializer;
    data.MQTTVersion = MQTT_VERSION_v311;

    data.clientID.cstring = DEFAULT_MQTT_CLIENT_ID;
    if (argc > 3) {
        data.clientID.cstring = argv[3];
    }

    data.username.cstring = DEFAULT_MQTT_USER;
    if (argc > 4) {
        data.username.cstring = argv[4];
    }

    data.password.cstring = DEFAULT_MQTT_PWD;
    if (argc > 5) {
        data.password.cstring = argv[5];
    }

    data.keepAliveInterval = DEFAULT_KEEPALIVE_SEC;
    if (argc > 6) {
        data.keepAliveInterval = atoi(argv[6]);
    }

    data.cleansession = IS_CLEAN_SESSION;
    data.willFlag = 0;

    printf("mqtt_example: Connecting to MQTT Broker from %s %d\n",
            remote_ip, port);
    printf("mqtt_example: Trying to connect to %s, port: %d\n",
            remote_ip, port);
    ret = NetworkConnect(&network, remote_ip, port);
    if (ret < 0) {
        printf("mqtt_example: Unable to connect\n");
        return ret;
    }

    printf("user:%s clientId:%s password:%s\n", data.username.cstring,
             data.clientID.cstring, data.password.cstring);
    ret = MQTTConnect(&client, &data);
    if (ret < 0) {
        printf("mqtt_example: Unable to connect client %d\n", ret);
        _cmd_discon(0, NULL);
        return ret;
    }
    else {
        printf("mqtt_example: Connection successfully\n");
    }

    return (ret > 0) ? 0 : 1;
}

static int _cmd_pub(int argc, char **argv)
{
    enum QoS qos = QOS0;

    if (argc < 3) {
        printf("usage: %s <topic name> <string msg> [QoS level]\n",
               argv[0]);
        return 1;
    }
    if (argc == 4) {
        qos = get_qos(argv[3]);
    }
    MQTTMessage message;
    message.qos = qos;
    message.retained = IS_RETAINED_MSG;
    message.payload = argv[2];
    message.payloadlen = strlen(message.payload);

    int rc;
    if ((rc = MQTTPublish(&client, argv[1], &message)) < 0) {
        printf("mqtt_example: Unable to publish (%d)\n", rc);
    }
    else {
        printf("mqtt_example: Message (%s) has been published to topic %s"
               "with QOS %d\n",
               (char *)message.payload, argv[1], (int)message.qos);
    }

    return rc;
}

static int _cmd_sub(int argc, char **argv)
{
    enum QoS qos = QOS0;

    if (argc < 2) {
        printf("usage: %s <topic name> [QoS level]\n", argv[0]);
        return 1;
    }

    if (argc >= 3) {
        qos = get_qos(argv[2]);
    }

    if (topic_cnt > MAX_TOPICS) {
        printf("mqtt_example: Already subscribed to max %d topics,"
                "call 'unsub' command\n", topic_cnt);
        return -1;
    }

    if (strlen(argv[1]) > MAX_LEN_TOPIC) {
        printf("mqtt_example: Not subscribing, topic too long %s\n", argv[1]);
        return -1;
    }
    strncpy(_topic_to_subscribe[topic_cnt], argv[1], strlen(argv[1]));

    printf("mqtt_example: Subscribing to %s\n", _topic_to_subscribe[topic_cnt]);
    int ret = MQTTSubscribe(&client,
              _topic_to_subscribe[topic_cnt], qos, _on_msg_received);
    if (ret < 0) {
        printf("mqtt_example: Unable to subscribe to %s (%d)\n",
               _topic_to_subscribe[topic_cnt], ret);
        _cmd_discon(0, NULL);
    }
    else {
        printf("mqtt_example: Now subscribed to %s, QOS %d\n",
               argv[1], (int) qos);
        topic_cnt++;
    }
    return ret;
}

static int _cmd_unsub(int argc, char **argv)
{
    if (argc < 2) {
        printf("usage %s <topic name>\n", argv[0]);
        return 1;
    }

    int ret = MQTTUnsubscribe(&client, argv[1]);

    if (ret < 0) {
        printf("mqtt_example: Unable to unsubscribe from topic: %s\n", argv[1]);
        _cmd_discon(0, NULL);
    }
    else {
        printf("mqtt_example: Unsubscribed from topic:%s\n", argv[1]);
        topic_cnt--;
    }
    return ret;
}

static const shell_command_t shell_commands[] =
{
    { "con",    "connect to MQTT broker",             _cmd_con    },
    { "discon", "disconnect from the current broker", _cmd_discon },
    { "pub",    "publish something",                  _cmd_pub    },
    { "sub",    "subscribe topic",                    _cmd_sub    },
    { "unsub",  "unsubscribe from topic",             _cmd_unsub  },
    { NULL,     NULL,                                 NULL        }
};

static unsigned char buf[BUF_SIZE];
static unsigned char readbuf[BUF_SIZE];

static char *server_ip = MQTT_BROKER_IP;
static char *my_topic = CLIENT_TOPIC;

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

int main(void)
{
    if (IS_USED(MODULE_GNRC_ICMPV6_ECHO)) {
        msg_init_queue(_main_msg_queue, MAIN_QUEUE_SIZE);
    }
#ifdef MODULE_LWIP
    /* let LWIP initialize */
    ztimer_sleep(ZTIMER_MSEC, 1 * MS_PER_SEC);
#endif

    NetworkInit(&network);

    MQTTClientInit(&client, &network, COMMAND_TIMEOUT_MS, buf, BUF_SIZE,
                   readbuf,
                   BUF_SIZE);
    printf("Running mqtt paho example. Type help for commands info\n");

    MQTTStartTask(&client);

    char *cmd_con_m[3];
    cmd_con_m[0] = "con";
    cmd_con_m[1] = server_ip;
    cmd_con_m[2] = "1885";
    int cmd_con_count = 3;

    printf("Starting connection\n");
    while (_cmd_con(cmd_con_count, cmd_con_m))
    {
        printf("broker connection failed\n");
        printf("Trying again...\n");

        int randi = rand();
        float u1 = randi / RAND_MAX;                  // Normalized to [0, 1]
        int sleepDuration = (int)(u1 * 5000) + 10000; // Convert to milliseconds (0 to 1000 ms range)
        printf("Sleeping for : %d ms\n", sleepDuration);
        ztimer_sleep(ZTIMER_MSEC, sleepDuration);
    }
    printf("connection okay\n");

    int array_length = 0;

    int cmd_pub_count = 3;
    char *cmd_pub[cmd_pub_count];
    cmd_pub[0] = "pub";
    cmd_pub[1] = my_topic;
    char temp_str[10];
    cmd_pub[2] = temp_str;

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
                
                sprintf(temp_str, "%i", rounded_avg_temp);
                printf("Temp Str: %s\n", temp_str);
                if (_cmd_pub(cmd_pub_count, cmd_pub))
                {
                    printf("No of ele: %i\n", numElements);
                }

                for (int i = 0; i < array_length - 1; ++i)
                {
                    data.tempList[i] = data.tempList[i + 1];
                }
                array_length--;
            }
        }

        int randi = rand();
        float u1 = randi / RAND_MAX;
        int sleepDuration = (int)(u1 * 5000) + 30000; // delay of 1-2 seconds
        printf("Sleeping for : %d ms\n", sleepDuration);
        ztimer_sleep(ZTIMER_MSEC, sleepDuration);
    }

    char line_buf[SHELL_DEFAULT_BUFSIZE];
    shell_run(shell_commands, line_buf, SHELL_DEFAULT_BUFSIZE);
    return 0;
}
