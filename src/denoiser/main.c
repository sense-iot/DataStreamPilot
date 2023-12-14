#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include "ztimer.h"
#include "shell.h"

#define ENABLE_DEBUG 1
#include "debug.h"

#define NUM_SENSORS 3

// Function to check for outliers using z-scores
int is_outlier(float readings[NUM_SENSORS], float z_threshold) {
    // Calculate mean of the readings
    float mean_reading = 0.0;
    for (int i = 0; i < NUM_SENSORS; i++) {
        mean_reading += readings[i];
    }
    mean_reading /= NUM_SENSORS;

    // Calculate standard deviation of the readings
    float std_dev_reading = 0.0;
    for (int i = 0; i < NUM_SENSORS; i++) {
        std_dev_reading += (float)pow((double)(readings[i] - mean_reading), 2);  
    }
    std_dev_reading = sqrt(std_dev_reading / NUM_SENSORS);

    // Calculate z-score for each sensor
    int is_outlier = 0;
    for (int i = 0; i < NUM_SENSORS; i++) {
        float z_score = fabs((readings[i] - mean_reading) / std_dev_reading);
        if (z_score > z_threshold) {
            is_outlier = 1;
            break;
        }
    }
    DEBUG_PRINT("is_outlier: %i\n", is_outlier);
    return is_outlier;
}

int main(void) {
    ztimer_sleep(ZTIMER_SEC, 5);
    puts("Hello from RIOT!");

    char temp1_str[10];

    // Assuming one set of readings from each sensor at a specific time
    float sensor_readings[NUM_SENSORS] = {25.5, 25.3, 25.6};  // Replace with actual readings

    DEBUG_PRINT("Program started.. \n");

    sprintf(temp1_str, "%f", (double)sensor_readings[0]);
         DEBUG_PRINT("Processed Reading: Sensor1=%s, Sensor2=%f, Sensor3=%f\n",
                temp1_str, (double)sensor_readings[1], (double)sensor_readings[2]);

    // Set z-score threshold (adjust based on your requirements)
    // float z_threshold = 2.0;

    // // Check for outliers
    //  if (!is_outlier(sensor_readings, z_threshold)) {
    //      // Process the readings (replace with your processing logic)
    //      sprintf(temp1_str, "%f", (double)sensor_readings[0]);
    //      DEBUG_PRINT("Processed Reading: Sensor1=%s, Sensor2=%f, Sensor3=%f\n",
    //             temp1_str, (double)sensor_readings[1], (double)sensor_readings[2]);
    //  } else {
    //      // Handle outlier case
    //      DEBUG_PRINT("Outlier detected. Ignoring the reading.\n");
    //  }

    return 0;
}
