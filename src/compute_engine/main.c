#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#include "thread.h"
#include "ztimer.h"
#include "msg.h"

#include "lpsxxx.h"
#include "lpsxxx_params.h"
#include "lpsxxx_internal.h"
#include "periph/i2c.h"
#include "net/gcoap.h"
#include "ztimer.h"

#define ENABLE_DEBUG 1
#include "debug.h"

#define MAIN_QUEUE_SIZE (4)
static msg_t _main_msg_queue[MAIN_QUEUE_SIZE];

extern int gcoap_cli_cmd(int argc, char **argv);
extern void gcoap_cli_init(void);

static char *server_ip = GCOAP_AMAZON_SERVER_IP_ONLY;
#define MAX_JSON_PAYLOAD_SIZE 128
char json_payload[MAX_JSON_PAYLOAD_SIZE];

#define EMCUTE_PRIO (THREAD_PRIORITY_MAIN - 1)
#define NUMOFSUBS (16U)
#define TOPIC_MAXLEN (64U)

#define MAX_IP_LENGTH 46 // Maximum length for an IPv6 address

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

/*
  % r - accuracy (5%),
  % s - standard deviation,
  % x - Average,
  % z = 1.960 (95%) - TAKE THE CEIL
  % N = (100*z*s/(r*x))^2
*/
#define WINDOW_SIZE 62

typedef struct
{
  int16_t tempList[WINDOW_SIZE];
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

// check for the boot bit is set back to zero or not
void bootDealay(const lpsxxx_t *dev)
{

  uint8_t val;
  int i = 0;
  while (1)
  {
    ztimer_sleep(ZTIMER_MSEC, 100);
    int ret = i2c_read_reg(DEV_I2C, DEV_ADDR, LPSXXX_REG_CTRL_REG2, &val, 0);
    if (ret < 0)
    {
      return;
    }
    if ((val & (1 << 7)) == 0)
    {
      return;
    }
    i += 1;
    if (i >= 5) // 5 second dealy
    {
      printf("Sensor boot delay failed\n");
      return;
    }
  }
  ztimer_sleep(ZTIMER_MSEC, 5000);
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

  if (temp_sensor_write_CTRL_REG2_value(&lpsxxx, (1 << 7) | (1 << 2)) != LPSXXX_OK)
  {
    puts("Sensor reset failed");
  }
  bootDealay(&lpsxxx);

  ztimer_sleep(ZTIMER_MSEC, 5000);

  if (lpsxxx_init(&lpsxxx, &paramts) != LPSXXX_OK)
  {
    puts("Sensor initialization failed");
  }

  ztimer_sleep(ZTIMER_MSEC, 5000);

  // 0x40 -- 01000000
  // AVGT2 AVGT1 AVGT0 100 --  Nr. internal average : 16
  if (temp_sensor_write_res_conf(&lpsxxx, 0x40) != LPSXXX_OK)
  {
    puts("Sensor enable failed");
  }

  if (lpsxxx_enable(&lpsxxx) != LPSXXX_OK)
  {
    puts("Sensor enable failed");
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

#define DEVIATION_FACTOR 2 // Defines how many standard deviations away from the mean to consider as outlier

float calculate_stddev(int16_t *data, int size, double mean)
{
  double sum = 0.0;
  for (int i = 0; i < size; i++)
  {
    sum += pow(data[i] - mean, 2);
  }
  return sqrt(sum / size);
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

// Function to calculate odd parity
int calculate_odd_parity(int16_t num)
{
  int8_t count = 0;
  for (int i = 0; i < 16; ++i)
  { // Assuming 16-bit integers
    if (num & 1)
    {
      count++;
    }
    num >>= 1;
  }
  return (count % 2 == 0) ? 1 : 0;
}

void remove_outliers(int16_t *data, int size, float mean, float stddev)
{
  int j = 0;
  for (int i = 0; i < size; i++)
  {
    if (fabs((float)data[i] - mean) <= DEVIATION_FACTOR * stddev)
    {
      data[j++] = data[i];
    }
  }
}

char parity_bit[4];
int main(void)
{
  ztimer_sleep(ZTIMER_MSEC, 5000);
  printf("Sensor data averaged - Group 12 MQTT\n");
  printf("Sensor ID : %s\n", SENSOR_ID);

  if (temp_sensor_reset() == 0)
  {
    printf("Sensor reset failed in the main loop\n");
  }
  ztimer_sleep(ZTIMER_MSEC, 4000);
  setup_coap_client();
  msg_init_queue(_main_msg_queue, MAIN_QUEUE_SIZE);

  ztimer_sleep(ZTIMER_MSEC, 4000);
  unsigned int site_name = getBinaryValue(locationMap, SITE_NAME);

  char *coap_command[6];
  coap_command[0] = "coap";
  coap_command[1] = "post";
  coap_command[2] = server_ip;
  coap_command[3] = "5683";
  coap_command[4] = "/temp";
  coap_command[5] = json_payload;

  const int message_arg_count = 6;

  int current_index = 0;

  // initialize the array
  for (int i = 0; i < WINDOW_SIZE; i++)
  {
    data.tempList[i] = 0;
  }

  while (1)
  {
    int16_t temp = 0;
    if (lpsxxx_read_temp(&lpsxxx, &temp) != LPSXXX_OK)
    {
      int16_t temp_n_noise = temp + (int16_t)add_noise(789.2);
      // printf("Temperature with noise: %i.%u°C\n", (temp_n_noise / 100), (temp_n_noise % 100));
      data.tempList[current_index++] = temp_n_noise;

      if (current_index == WINDOW_SIZE)
      {
        current_index = 0;
      }

      int32_t sum = 0;
      for (int i = 0; i < WINDOW_SIZE; i++)
      {
        sum += data.tempList[i];
      }

      double avg_temp = (double)sum / WINDOW_SIZE;
      float stddev = calculate_stddev(data.tempList, WINDOW_SIZE, avg_temp);
      remove_outliers(data.tempList, WINDOW_SIZE, avg_temp, stddev);

      int newsum = 0;
      for (int i = 0; i < WINDOW_SIZE; i++)
      {
        newsum += data.tempList[i];
      }
      double new_avg_temp = (double)sum / WINDOW_SIZE;
      int16_t rounded_avg_temp = (int16_t)round(new_avg_temp);
      printf("Average temperature: %i.%u°C\n", (rounded_avg_temp / 100), (rounded_avg_temp % 100));

      int parity = calculate_odd_parity(rounded_avg_temp);

      int snprintf_result = snprintf(json_payload, sizeof(json_payload),
                                     "{\"site\": \"%d\", \"sensor\": \"%s\", \"value\": \"%d, %d\"}",
                                     site_name, SENSOR_ID, rounded_avg_temp, parity);

      // Check if snprintf was successful
      if (snprintf_result < 0 || snprintf_result >= (int)sizeof(json_payload))
      {
        fprintf(stderr, "Error creating JSON payload\n");
        return 1;
      }
      // Use the JSON payload string as needed
      printf("JSON Payload: %s\n", json_payload);
      gcoap_cli_cmd(message_arg_count, coap_command);
    }

    int randi = rand();
    float u1 = randi / RAND_MAX;
    int sleepDuration = (int)(u1 * 1000) + 5000; // delay of 1-2 seconds
    printf("Sleeping for : %d ms\n", sleepDuration);

    // This is to handle border router crashing
    ztimer_sleep(ZTIMER_MSEC, sleepDuration);
  }

  return 0;
}
