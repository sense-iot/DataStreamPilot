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
int is_outlier(int16_t readings[NUM_SENSORS], float z_threshold) {
    // Calculate mean of the readings
    float mean_reading = 0.0;
    for (int i = 0; i < NUM_SENSORS; i++) {
        mean_reading += readings[i];
    }
    mean_reading /= NUM_SENSORS;

    double mean_reading_d = mean_reading * 100;    // Debugging
    printf("Mean = %i\n", (int)mean_reading_d);    // Debugging

    // Calculate standard deviation of the readings
    float std_dev_reading = 0.0;
    for (int i = 0; i < NUM_SENSORS; i++) {
        std_dev_reading += (float)pow((double)(readings[i] - mean_reading), 2);  
    }
    std_dev_reading = sqrt(std_dev_reading / NUM_SENSORS);

    int16_t sd = std_dev_reading * 100;   // Debugging
    printf("SD = %i\n", (int)sd);       // Debugging

    // Calculate z-score for each sensor
    int is_outlier = 0;
    for (int i = 0; i < NUM_SENSORS; i++) {
        float z_score = fabs((readings[i] - mean_reading) / std_dev_reading);

        int16_t z_score_int = (int16_t)(z_score * 1000);   // Debugging   
        DEBUG_PRINT("Z score = %i\n", z_score_int);     // Debugging

        if (z_score > z_threshold) {
            is_outlier = 1;
            break;
        }
    }
    DEBUG_PRINT("is_outlier: %i\n", is_outlier);
    return is_outlier;
}

int main(void) {
    ztimer_sleep(ZTIMER_SEC, 1);
    puts("Hello from RIOT!");

    // Assuming one set of readings from each sensor at a specific time
    int16_t sensor_readings[NUM_SENSORS] = {4150, 4250, 4450};  // Replace with actual readings

    // Set z-score threshold (adjust based on your requirements)
    float z_threshold = 1.3;

    // Check for outliers
     if (!is_outlier(sensor_readings, z_threshold)) {
         // Process the readings (replace with your processing logic)
         DEBUG_PRINT("Processed Reading: Sensor1 = %i, Sensor2 = %i, Sensor3 = %i\n",
                sensor_readings[0], sensor_readings[1], sensor_readings[2]);
     } else {
         // Handle outlier case
         DEBUG_PRINT("Outlier detected. Ignoring the reading.\n");
     }

    return 0;
}
