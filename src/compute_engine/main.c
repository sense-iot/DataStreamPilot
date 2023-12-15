#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#include "thread.h"
#include "ztimer.h"

#include "mutex.h"

#include "lpsxxx.h"
#include "lpsxxx_params.h"

#include "msg.h"

#include "net/gcoap.h"
#include "net/ipv6/addr.h"
#include "net/sock/util.h"
#include "shell.h"
#include "net/utils.h"
#include "od.h"
#include "ztimer.h"
#include "mutex.h"

#include "gcoap_example.h"

#define ENABLE_DEBUG 1
#include "debug.h"


typedef struct {
  char buffer[128];
  int16_t tempList[5];
} data_t;

static data_t data;

static lpsxxx_t lpsxxx;
// static mutex_t lps_lock = MUTEX_INIT;

#define LPSXXX_REG_RES_CONF (0x10)
#define LPSXXX_REG_CTRL_REG2 (0x21)
#define DEV_I2C (dev->params.i2c)
#define DEV_ADDR (dev->params.addr)
#define DEV_RATE (dev->params.rate)
#define MAX_JSON_PAYLOAD_SIZE 256

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


// Function to calculate odd parity 
int calculate_odd_parity(int16_t num) {
    int8_t count = 0;
    for (int i = 0; i < 16; ++i) { // Assuming 16-bit integers
        if (num & 1) {
            count++;
        }
        num >>= 1;
    }
    return (count % 2 == 0) ? 1 : 0;
}

#define MAIN_QUEUE_SIZE (4)
static msg_t _main_msg_queue[MAIN_QUEUE_SIZE];

void setup_coap_client(void) {
    msg_init_queue(_main_msg_queue, MAIN_QUEUE_SIZE);
    ztimer_sleep(ZTIMER_MSEC, 1000);
}

float generate_normal_random(float stddev) {
    float M_PI = 3.1415926535;

    // Box-Muller transform to generate random numbers with normal distribution
    float u1 = rand() / (float)RAND_MAX;
    float u2 = rand() / (float)RAND_MAX;
    float z = sqrt(-2 * log(u1)) * cos(2 * M_PI * u2);
    
    return stddev * z;
}

float add_noise(float stddev) {
    int num;
    float noise_val = 0;
    
    num = rand() % 100 + 1; // use rand() function to get the random number
    if (num >= 30) {
        // Generate a random number with normal distribution based on a stddev
        noise_val = generate_normal_random(stddev);
    }
    return noise_val;
}

// Define a structure to hold the location name and its corresponding binary value
struct LocationMapping {
    const char *location;
    unsigned int binaryValue;
};

// Function to retrieve the binary value based on the location name
unsigned int getBinaryValue(const struct LocationMapping *mapping, const char *location) {
    for (int i = 0; mapping[i].location != NULL; ++i) {
        if (strcmp(mapping[i].location, location) == 0) {
            return mapping[i].binaryValue;
        }
    }
    // Return a default value (e.g., 000) if the location is not found
    return 0;
}

int main(void) {

  struct LocationMapping locationMap[] = {
        {"UNKNOWN", 0b000},
        {"grenoble", 0b001},
        {"paris", 0b010},
        {"lille", 0b011},
        {"saclay", 0b100},
        {"strasbourg", 0b101},
        {NULL, 0}
    };

  srand(evtimer_now_msec());
  
  unsigned int site_name = getBinaryValue(locationMap, SITE_NAME);

  if (temp_sensor_reset() == 0) {
    puts("Sensor failed");
    return 1;
  }

  int counter = 0;
  int parity;
  int16_t base_value = 0;

  while (1) {
    
    int16_t temp = 0;
    
    if (lpsxxx_read_temp(&lpsxxx, &temp) == LPSXXX_OK) {

      char temp_str[10];
      char parity_bit[4];

      temp += (int) add_noise(789.2);

      DEBUG_PRINT("temp: %i base_value: %i\n", temp, base_value);

      if (counter == 0) {
        base_value = temp;
        sprintf(temp_str, "%i,", temp);
        strcat(data.buffer, temp_str);
      }
      else {
        temp -= base_value;// threshold = 128
        temp = (temp < -128) ? -128 : (temp > 127) ? 127 : temp;
        sprintf(temp_str, "%i,", temp);
        strcat(data.buffer, temp_str);
      }

      parity = calculate_odd_parity(temp);
      sprintf(parity_bit, "%i,", parity);
      strcat(data.buffer, parity_bit);

      counter++;

    }

    if (counter == 10) {

      DEBUG_PRINT("Data: %s\n", data.buffer);
      DEBUG_PRINT("site: %d\n", site_name);
      ztimer_sleep(ZTIMER_MSEC, 1000);

      // Create a JSON-like string manually
      char json_payload[MAX_JSON_PAYLOAD_SIZE];
      int snprintf_result = snprintf(json_payload, sizeof(json_payload),
                                   "{\"site\": \"%d\", \"temperature\": \"%s\"}",
                                   site_name, data.buffer);

      // Check if snprintf was successful
      if (snprintf_result < 0 || snprintf_result >= (int) sizeof(json_payload)) {
          fprintf(stderr, "Error creating JSON payload\n");
          return 1;
      }

      // Use the JSON payload string as needed
      printf("JSON Payload: %s\n", json_payload);


      gcoap_post(json_payload, TEMP);
      memset(data.buffer, 0, sizeof(data.buffer));
      counter = 0;
    }

    ztimer_sleep(ZTIMER_MSEC, 1000);

  }

  return 0;
}
