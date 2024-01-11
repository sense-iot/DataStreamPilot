#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

// #include "thread.h"
#include "ztimer.h"
#include "msg.h"

#include "lpsxxx.h"
#include "lpsxxx_params.h"
#include "lpsxxx_internal.h"
#include "periph/i2c.h"
#include "net/gcoap.h"
#include "ztimer.h"

// #include "debug.h"
// #define MODULE_LPS331AP 1

/*
  % r - accuracy (5%),
  % s - standard deviation,
  % x - Average,
  % z = 1.960 (95%) - TAKE THE CEIL
  % N = (100*z*s/(r*x))^2
*/
#define WINDOW_SIZE 65
/*
  Defines how many standard deviations away from the mean to consider as outlier
*/
#define DEVIATION_FACTOR 2.0

typedef struct
{
  int16_t tempList[WINDOW_SIZE];
} data_t;

static data_t data;
static lpsxxx_t lpsxxx;
static const lpsxxx_params_t simpleDeviceParams = {.i2c = lpsxxx_params[0].i2c,
                                                   .addr = lpsxxx_params[0].addr,
                                                   .rate = lpsxxx_params[0].rate};

extern int gcoap_cli_cmd(int argc, char **argv);
extern void gcoap_cli_init(void);

static char *server_ip = GCOAP_AMAZON_SERVER_IP_ONLY;
#define MAX_JSON_PAYLOAD_SIZE 128
char json_payload[MAX_JSON_PAYLOAD_SIZE];

#define MAIN_QUEUE_SIZE (4)
static msg_t _main_msg_queue[MAIN_QUEUE_SIZE];
char parity_bit[4];

void setup_coap_client(void)
{
  msg_init_queue(_main_msg_queue, MAIN_QUEUE_SIZE);
  ztimer_sleep(ZTIMER_MSEC, 2000);
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

int write_register_value(const lpsxxx_t *dev, uint16_t reg, uint8_t value)
{
  i2c_acquire(dev->params.i2c);
  if (i2c_write_reg(dev->params.i2c, dev->params.addr, reg, value, 0))
  {
    i2c_release(dev->params.i2c);
    return -LPSXXX_ERR_I2C;
  }
  i2c_release(dev->params.i2c);

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
    int ret = i2c_read_reg(dev->params.i2c, dev->params.addr, LPSXXX_REG_CTRL_REG2, &val, 0);
    if (ret < 0)
    {
      return;
    }
    // At the end of the boot process the BOOT bit is set again to ‘0’.
    // BOOT bit takes effect after one ODR clock cycle.
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
  // cold start delay
  ztimer_sleep(ZTIMER_MSEC, 1000);
  lpsxxx.params = simpleDeviceParams;

  if (lpsxxx_init(&lpsxxx, &lpsxxx.params) != LPSXXX_OK)
  {
    puts("Sensor initialization failed");
  }
  ztimer_sleep(ZTIMER_MSEC, 1000);

  // reset the sensor
  if (temp_sensor_write_CTRL_REG2_value(&lpsxxx, (1 << 7) | (1 << 2)) != LPSXXX_OK)
  {
    puts("Sensor reset failed");
  }
  bootDealay(&lpsxxx);

  ztimer_sleep(ZTIMER_MSEC, 1000);

  if (lpsxxx_enable(&lpsxxx) != LPSXXX_OK)
  {
    puts("Sensor enable failed");
    return 1;
  }
  ztimer_sleep(ZTIMER_MSEC, 2000);
  return 0;
}

float generate_normal_random(float stddev)
{
  float M_PI = 3.1415926535;
  float u1 = rand() / (float)RAND_MAX;
  float u2 = rand() / (float)RAND_MAX;
  float z = sqrt(-2 * log(u1)) * cos(2 * M_PI * u2);
  return stddev * z;
}

float calculate_stddev(int16_t *data, float mean)
{
  double sum = 0.0;
  for (int i = 0; i < WINDOW_SIZE; i++)
  {
    sum += pow(data[i] - mean, 2);
  }
  return sqrt(sum / WINDOW_SIZE);
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

void remove_outliers(int16_t *data, float mean, float stddev)
{
  int j = 0;
  for (int i = 0; i < WINDOW_SIZE; i++)
  {
    if (fabsf((float)data[i] - mean) <= DEVIATION_FACTOR * stddev)
    {
      data[j++] = data[i];
    } else {
      printf("Outlier detected: %d\n", data[i]);
      data[j++] = 0;
    }
  }
}

double calculate_average(int16_t *data)
{
  double sum = 0.0;
  int count = 0;
  double average = 0.0;
  for (int i = 0; i < WINDOW_SIZE; i++)
  {
    if (data[i] != 0) {
      sum += data[i];
      count = count + 1;
    }
  }

  average = sum / count;
  return average;
}

volatile double sum;
volatile float avg_temp;
volatile int16_t rounded_avg_temp;
volatile float stddev;

int main(void)
{
  int resetValue;
  unsigned int site_name;
  int message_arg_count;
  int current_index;
  int i;
  float u1;
  int parity;
  int snprintf_result;
  int randi;
  int sleepDuration;
  setvbuf(stdout, malloc(2048), _IOFBF, 2048);

  char *coap_command[6];
  coap_command[0] = "coap";
  coap_command[1] = "post";
  coap_command[2] = server_ip;
  coap_command[3] = "5683";
  coap_command[4] = "/temp";
  coap_command[5] = json_payload;

  ztimer_sleep(ZTIMER_MSEC, 5000);
  printf("Sensor data averaged - Group 12 MQTT\n");
  printf("Sensor ID : %s\n", SENSOR_ID);

  resetValue = temp_sensor_reset();
  if (resetValue == -1)
  {
    printf("Sensor reset failed in the main loop : %d\n", resetValue);
  }
  fflush(stdout);
  setup_coap_client();

  ztimer_sleep(ZTIMER_MSEC, 4000);
  site_name = getBinaryValue(locationMap, SITE_NAME);

  message_arg_count = 6;
  current_index = 0;

  // initialize the sensor data list with initial temp or hardcoded 35.0
  int16_t initial_temp = 0;
  lpsxxx_read_temp(&lpsxxx, &initial_temp);
  for (i = 0; i < WINDOW_SIZE; i++)
  {
    data.tempList[i] = initial_temp;
  }

  while (1)
  {
    int16_t temp = 0;
    int ret = lpsxxx_read_temp(&lpsxxx, &temp);
    if (ret == LPSXXX_OK)
    {
      printf("DataStreamPilot: ------------------------\n");
      printf("DataStreamPilot: Original value : %i.%u°C\n", (temp / 100), (temp % 100));
      int16_t temp_n_noise = temp + (int16_t)add_noise(789.2);
      printf("DataStreamPilot: avg_temp : %d\n", (int)(avg_temp));
      printf("DataStreamPilot: stddev   : %d\n", (int)(stddev));

      if (fabsf(temp_n_noise - avg_temp) <= DEVIATION_FACTOR * stddev)
      {
        printf("DataStreamPilot: GOOD Temp with noise: %i.%u°C\n", (temp_n_noise / 100), (temp_n_noise % 100));
      } else {
        printf("DataStreamPilot: BAD Temp with noise: %i.%u°C\n", (temp_n_noise / 100), (temp_n_noise % 100));
      }

      data.tempList[current_index++] = temp_n_noise;

      if (current_index >= WINDOW_SIZE)
      {
        current_index = 0;
      }

      sum = 0;
      i = 0;
      for (i = 0; i < WINDOW_SIZE; i++)
      {
        sum += data.tempList[i];
      }

      // // Print tempList
      // printf("tempList: [");
      // for (i = 0; i < WINDOW_SIZE; i++)
      // {
      //   printf("%d", data.tempList[i]);
      //   if (i < WINDOW_SIZE - 1)
      //   {
      //     printf(", ");
      //   }
      // }
      // printf("]\n");

      avg_temp = sum / WINDOW_SIZE;
      stddev = calculate_stddev(data.tempList, avg_temp);
      remove_outliers(data.tempList, avg_temp, stddev);

      // Print tempList
      // printf("tempList Cleaned: [");
      // for (i = 0; i < WINDOW_SIZE; i++)
      // {
      //   printf("%d", data.tempList[i]);
      //   if (i < WINDOW_SIZE - 1)
      //   {
      //     printf(", ");
      //   }
      // }
      // printf("]\n");

      avg_temp = calculate_average(data.tempList);
      stddev = calculate_stddev(data.tempList, avg_temp);
      rounded_avg_temp = (int16_t)round(avg_temp);
      // printf("Avg temp: %i.%u°C\n", (rounded_avg_temp / 100), (rounded_avg_temp % 100));

      parity = calculate_odd_parity(rounded_avg_temp);

      snprintf_result = snprintf(json_payload, sizeof(json_payload),
                                 "{\"site\": \"%d\", \"sensor\": \"%s\", \"value\": \"%d, %d\"}",
                                 site_name, SENSOR_ID, rounded_avg_temp, parity);

      // Check if snprintf was successful
      if (snprintf_result < 0 || snprintf_result >= (int)sizeof(json_payload))
      {
        fprintf(stderr, "Error creating JSON payload\n");
      }
      // Use the JSON payload string as needed
      printf("DataStreamPilot: JSON Payload: %s\n", json_payload);
      gcoap_cli_cmd(message_arg_count, coap_command);
    }
    else
    {
      printf("DataStreamPilot: Temp read failed\n");
    }

    randi = rand();
    u1 = randi / RAND_MAX;
    sleepDuration = (int)(u1 * 1000) + 1000; // delay of 1-2 seconds
    printf("DataStreamPilot: Sleeping for : %d ms for\n", sleepDuration);
    ztimer_sleep(ZTIMER_MSEC, sleepDuration);
  }

  return 0;
}
