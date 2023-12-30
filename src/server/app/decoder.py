import logging
from filterpy.kalman import KalmanFilter
import numpy as np

from collections import defaultdict
from configuration import sites

sensor_readings = defaultdict(list)
sensor_readings_processed = defaultdict(list)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("coap-server")
logger.setLevel(logging.DEBUG)

NUMBER_OF_SENSORS = 3
Z_THRESHOLD = 1.3

async def decodeTemperature(site, reading, sensor):
    global sensor_readings
    processed_value = None

    site_name = sites[site]

    reading = list(map(int, reading[:-1].strip().split(',')))
    logger.debug(f"Sensor reading: {reading}")

    reading, parity = reading[0], reading[1]

    if (parityCheck(reading, parity)):
        logger.debug(f"Initializing reading for site {site_name}")
        sensor_readings[site_name].append({sensor: reading})
    else:
        if 2 < len(sensor_readings[site_name]):
            logger.debug(f"mismatched{reading} {parity} {parityCheck(reading, parity)}" )
            prev_value = list(sensor_readings[site_name][-1].values())[0]
            prev_prev_value = list(sensor_readings[site_name][-2].values())[0]
            interpolated_value = (prev_value + prev_prev_value) / 2.0
            sensor_readings[site_name].append({sensor: interpolated_value})

    if len(sensor_readings[site_name])%NUMBER_OF_SENSORS == 0:
        logger.debug(f"Processing sensor readings for site {site_name}")
        reading_for_processing = np.array(sensor_readings[site_name][-NUMBER_OF_SENSORS:])
        logger.debug(f"Reading for processing: {reading_for_processing}")
        processed_value = filter_outliers(readings=reading_for_processing,  z_threshold=Z_THRESHOLD)

        #keeping track of processed values
        sensor_readings_processed[site_name].append(processed_value)
        
    #memory optimizing
    if sensor_readings[site_name] and len(sensor_readings[site_name]) > NUMBER_OF_SENSORS*10:
        sensor_readings[site_name] = sensor_readings[site_name][-(NUMBER_OF_SENSORS*10):]

    return processed_value


#checking odd parity
def calculate_odd_parity(num):
    count = 0
    for i in range(16):  # Assuming 16-bit integers
        if num & 1:
            count += 1
        num >>= 1
    return count

def parityCheck(value, parity):
    ones_count = calculate_odd_parity(value)
    return (ones_count + int(parity)) % 2 == 1

def filter_outliers(readings, z_threshold):
    # Calculate mean of the readings
    mean_reading = np.mean(readings)

    print(f"Mean = {int(mean_reading * 100)}")  # Debugging

    # Calculate standard deviation of the readings
    std_dev_reading = np.std(readings)

    print(f"SD = {int(std_dev_reading * 100)}")  # Debugging

    # Filtering outliers
    z_scores = np.abs((readings - mean_reading) / std_dev_reading)

    print("Z scores:", (z_scores * 1000).astype(int))  # Debugging

    mask = z_scores <= z_threshold
    filtered_readings = readings[mask]
    new_mean_reading = np.mean(filtered_readings)

    print(f"New mean: {int(new_mean_reading * 100)}")  # Debugging

    return int(new_mean_reading)