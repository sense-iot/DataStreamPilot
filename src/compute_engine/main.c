#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "thread.h"
#include "ztimer.h"

#include "mutex.h"

#include "msg.h"

#include "net/gcoap.h"
#include "net/ipv6/addr.h"
#include "net/sock/util.h"
#include "shell.h"
#include "net/utils.h"
#include "od.h"
#include "ztimer.h"

#include "gcoap_example.h"

#define ENABLE_DEBUG 1
#include "debug.h"

#define EMCUTE_PRIO (THREAD_PRIORITY_MAIN - 1)
#define NUMOFSUBS (16U)
#define TOPIC_MAXLEN (64U)

static char stack[THREAD_STACKSIZE_DEFAULT];
static msg_t queue[8];

static emcute_sub_t subscriptions[NUMOFSUBS];
static char topics[NUMOFSUBS][TOPIC_MAXLEN];

#define MAX_IP_LENGTH 46 // Maximum length for an IPv6 address

char *denoised_data = NULL;

void setup_coap_client(void)
{
  msg_init_queue(_main_msg_queue, MAIN_QUEUE_SIZE);
  ztimer_sleep(ZTIMER_MSEC, 1000);
}

// Define a structure to hold the location name and its corresponding binary value
struct LocationMapping
{
  const char *location;
  unsigned int binaryValue;
};

// Function to retrieve the binary value based on the location name
unsigned int getBinaryValue(const struct LocationMapping *mapping, const char *location)
{
  for (int i = 0; mapping[i].location != NULL; ++i)
  {
    if (strcmp(mapping[i].location, location) == 0)
    {
      return mapping[i].binaryValue;
    }
  }
  // Return a default value (e.g., 000) if the location is not found
  return 0;
}

struct LocationMapping locationMap[] = {
    {"UNKNOWN", 0b000},
    {"grenoble", 0b001},
    {"paris", 0b010},
    {"lille", 0b011},
    {"saclay", 0b100},
    {"strasbourg", 0b101},
    {NULL, 0}};

static char stack[THREAD_STACKSIZE_DEFAULT];
static msg_t queue[8];

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

  // 7       6543    2          1      0
  // BOOT RESERVED SWRESET AUTO_ZERO ONE_SHOT
  //  1      0000   1      0            0
  // 44
  if (temp_sensor_write_CTRL_REG2_value(&lpsxxx, 0x44) != LPSXXX_OK)
  {
    printf("Sensor reset failed\n");
    return 0;
  }

  ztimer_sleep(ZTIMER_MSEC, 4000);

  if (lpsxxx_init(&lpsxxx, &paramts) != LPSXXX_OK)
  {
    printf("Sensor initialization failed\n");
    return 0;
  }

  ztimer_sleep(ZTIMER_MSEC, 4000);

  // 0x40 -- 01000000
  // AVGT2 AVGT1 AVGT0 100 --  Nr. internal average : 16
  if (temp_sensor_write_res_conf(&lpsxxx, 0x40) != LPSXXX_OK)
  {
    printf("Sensor enable failed\n");
    return 0;
  }

  ztimer_sleep(ZTIMER_MSEC, 4000);
  if (lpsxxx_enable(&lpsxxx) != LPSXXX_OK)
  {
    printf("Sensor enable failed\n");
    return 0;
  }

  ztimer_sleep(ZTIMER_MSEC, 4000);
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

int main(void)
{
  ztimer_sleep(ZTIMER_MSEC, 5000);
  printf("Sensor data averaged - Group 12 MQTT\n");
  printf("Sensor ID : %s\n", EMCUTE_ID);
  printf("Topic : %s\n", CLIENT_TOPIC);

  if (temp_sensor_reset() == 0)
  {
    printf("Sensor failed\n");
  }

  ztimer_sleep(ZTIMER_MSEC, 4000);
  unsigned int site_name = getBinaryValue(locationMap, SITE_NAME);

  int array_length = 0;

  while (1)
  {

    int16_t temp = 0;
    if (lpsxxx_read_temp(&lpsxxx, &temp) == LPSXXX_OK)
    {

      int16_t temp_n_noise = temp + (int16_t)add_noise(789.2);
      printf("Temperature with noise: %i.%u°C\n", (temp_n_noise / 100), (temp_n_noise % 100));
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

        char json_payload[MAX_JSON_PAYLOAD_SIZE];
        int snprintf_result = snprintf(json_payload, sizeof(json_payload),
                                       "{\"site\": \"%d\", \"sensor\": \"%s\", \"value\": \"%d\"}",
                                       site_name, EMCUTE_ID, rounded_avg_temp);

        // Check if snprintf was successful
        if (snprintf_result < 0 || snprintf_result >= (int)sizeof(json_payload))
        {
          fprintf(stderr, "Error creating JSON payload\n");
          return 1;
        }

        // Use the JSON payload string as needed
        printf("JSON Payload: %s\n", json_payload);

        gcoap_post(json_payload, TEMP);
        memset(data.buffer, 0, sizeof(data.buffer));

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
}

return 0;
}
