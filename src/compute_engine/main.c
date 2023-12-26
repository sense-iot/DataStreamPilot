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


typedef struct {
  char buffer[128];
  int16_t tempList[5];
} data_t;

static data_t data;

#define MAX_JSON_PAYLOAD_SIZE 256

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

struct LocationMapping locationMap[] = {
    {"UNKNOWN", 0b000},
    {"grenoble", 0b001},
    {"paris", 0b010},
    {"lille", 0b011},
    {"saclay", 0b100},
    {"strasbourg", 0b101},
    {NULL, 0}};

int main(void) {

  srand(evtimer_now_msec());
  
  unsigned int site_name = getBinaryValue(locationMap, SITE_NAME);

  int counter = 0;
  int parity;
  int16_t base_value = 0;

  while (1) {
    
    int16_t temp = 3250;
    int is_base = 0;

    if (temp > 30) {

      char temp_str[10];
      char parity_bit[4];

      DEBUG_PRINT("temp: %i base_value: %i\n", temp, base_value);
      
      counter = counter % 10;

      if (counter == 0) {
        base_value = temp;
        sprintf(temp_str, "%i,", temp);
        strcat(data.buffer, temp_str);
        is_base = 1;
      }
      else {
        temp -= base_value;
        temp = (temp < -128) ? -128 : (temp > 127) ? 127 : temp; // threshold = 128
        sprintf(temp_str, "%i,", temp);
        strcat(data.buffer, temp_str);
      }

      parity = calculate_odd_parity(temp);
      sprintf(parity_bit, "%i,", parity);
      strcat(data.buffer, parity_bit);

      DEBUG_PRINT("Data: %s\n", data.buffer);
      DEBUG_PRINT("site: %d\n", site_name);
      ztimer_sleep(ZTIMER_MSEC, 1000);

      // Create a JSON-like string manually
      char json_payload[MAX_JSON_PAYLOAD_SIZE];
      int snprintf_result = snprintf(json_payload, sizeof(json_payload),
                                   "{\"s\": \"%d\", \"t\": \"%s\", \"b\": \"%d\"}",
                                   site_name, data.buffer, is_base);

      // Check if snprintf was successful
      if (snprintf_result < 0 || snprintf_result >= (int) sizeof(json_payload)) {
          fprintf(stderr, "Error creating JSON payload\n");
          return 1;
      }

      // Use the JSON payload string as needed
      printf("JSON Payload: %s\n", json_payload);


      gcoap_post(json_payload, TEMP);
      memset(data.buffer, 0, sizeof(data.buffer));

      counter++;
    }

    ztimer_sleep(ZTIMER_MSEC, 1000);

  }

  return 0;
}
