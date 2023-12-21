## Denoiser node

This node is responsible for removing temperature values if they are vary too much from the other values.

In this project we are using 3 sensor nodes to collect temperature values simultaneously. These values published to 3 MQTT topics. Denoiser node consume those 3 values and run it's algorithm to identify outliers if there are any.

The filtering mechanism works as follows.

1. Calculate mean and standard deviation of three temperature values that reported at the same time from three different sensors. (Assume sensors are located nearby)
  
2. Then calculate the z value for all three temperature values individually.
  
3. Compare z value with the pre configured threshold value to identify outliers.
  
4. Since we are taking 3 values for this outlier detection we can only find one outlier.
  
5. If there is an outlier, we ignore that value and take the average of other two values.
  
6. Else, we get the average of all three values.
  

After filtering we publish that temperature value to an another topic called "filtered_temp".