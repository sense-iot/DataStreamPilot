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
#include "net/emcute.h"
#include "mutex.h"

#include "gcoap_example.h"

#define ENABLE_DEBUG 1
#include "debug.h"

#define EMCUTE_PRIO (THREAD_PRIORITY_MAIN - 1)
#define NUMOFSUBS (16U)
#define TOPIC_MAXLEN (64U)

static char stack[THREAD_STACKSIZE_DEFAULT];
static msg_t queue[8];

static emcute_sub_t subscriptions[NUMOFSUBS];

#define MAX_IP_LENGTH 46 // Maximum length for an IPv6 address

#define EMCUTE_ID ("compute_engine")

static char *server_ip = MQTT_BROKER_IP;

static mutex_t cb_lock = MUTEX_INIT;

char *denoised_data = NULL;

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

static void on_pub(const emcute_topic_t *topic, void *data, size_t len)
{
  char *in = (char *)data;

  printf("### got publication for topic '%s' [%i] ###\n", topic->name, (int)topic->id);
  printf("Data : %s \n", in);

  if (denoised_data == NULL)
  {
    denoised_data = malloc(len + 1);
    strncpy(denoised_data, in, len);
    denoised_data[len] = '\0';
  }
  else
  {
    free(denoised_data);
    denoised_data = malloc(len + 1);
    strncpy(denoised_data, in, len);
    denoised_data[len] = '\0';
  }

  printf("Denoised data : %s \n", denoised_data);

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

  

void unsubscribeFromTopics(void)
{
  char *unsub_message[2];
  unsub_message[0] = "sub";
  unsub_message[1] = "d";
  cmd_unsub(2, unsub_message);
}

void subscribeToTopics(void)
{
  char *sub_message[2];
  sub_message[0] = "sub";
  sub_message[1] = "d";
  cmd_sub_1(2, sub_message, on_pub);
}

int main(void) {

  unsubscribeFromTopics();
  subscribeToTopics();
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
