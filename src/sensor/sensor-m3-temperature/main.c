#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#include "thread.h"
#include "ztimer.h"
#include "shell.h"

#include "mutex.h"

#include "lpsxxx.h"
#include "lpsxxx_params.h"

#define ENABLE_DEBUG 1
#include "debug.h"

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

// int calculate_odd_parity(int num) {
//     int parityBit = 0;
//     int count = 0;  // To count the number of set bits

//     // Count the number of set bits (1-bits) in the given number
//     while (num) {
//         count += num & 1;  // Increment count if rightmost bit is set
//         num >>= 1;  // Right shift num to check the next bit
//     }

//     // Set parityBit to 1 if the count of set bits is even, else 0
//     parityBit = (count % 2 == 0) ? 1 : 0;

//     return parityBit;
// }

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
    if (num >= 50) {
        // Generate a random number with normal distribution based on a stddev
        noise_val = generate_normal_random(stddev);
    }
    return noise_val;
}

typedef struct {
  // char buffer[128];
  int16_t tempList[8];
} data_t;

static data_t data;

int main(void)
{
  if (temp_sensor_reset() == 0) {
    puts("Sensor failed");
    return 1;
  }

  // int16_t avg_temp = 0; 
  // int counter = 0;
  int array_length = 0;
  // int parity;

  while (1) {
    
    int16_t temp = 0;
    if (lpsxxx_read_temp(&lpsxxx, &temp) == LPSXXX_OK) {
      // DEBUG_PRINT("Temperature: %i.%u°C\n", (temp / 100), (temp % 100));
      
      int16_t temp_n_noise = temp + (int16_t)add_noise(789.2);
      // DEBUG_PRINT("Temperature with noise: %i.%u°C\n", (temp_n_noise / 100), (temp_n_noise % 100));
      if (array_length < 7) {
        data.tempList[array_length++] = temp_n_noise;
      }
      else {
        data.tempList[array_length++] = temp_n_noise;
        int32_t sum = 0;
        int numElements = array_length;
        // printf("No of ele: %i\n", numElements);
        for (int i = 0; i < numElements; i++) {
          sum += (int32_t)data.tempList[i];
          // printf("Temp List: %i.%u°C\n", (data.tempList[i] / 100), (data.tempList[i] % 100));
        }

        // printf("Sum: %li\n", sum);

        // avg_temp = sum / numElements;

        double avg_temp = (double)sum / numElements;

        // Round to the nearest integer
        int16_t rounded_avg_temp = (int16_t)round(avg_temp);

        char temp_str[10];
        // char parity_bit[4];

        sprintf(temp_str, "%i", rounded_avg_temp);
        printf("Temp Str: %s\n", temp_str);
        // strcat(data.buffer, temp_str);

        // parity = calculate_odd_parity(rounded_avg_temp);
        // sprintf(parity_bit, "%i,", parity);
        // // printf("Temp Str: %s°C\n", temp_str);
        // strcat(data.buffer, parity_bit);

        for (int i = 0; i < array_length - 1; ++i) {
            data.tempList[i] = data.tempList[i + 1];
        }
        array_length--;
        // counter++;
      }
    }
    // if (counter == 10) {
    //   DEBUG_PRINT("Data: %s\n", data.buffer);
    //   memset(data.buffer, 0, sizeof(data.buffer));
    //   counter = 0;
    // }
    ztimer_sleep(ZTIMER_MSEC, 1000);
  }

  return 0;
}
