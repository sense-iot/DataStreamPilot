import logging
from filterpy.kalman import KalmanFilter
import numpy as np

from collections import defaultdict
from configuration import sites

sensor_readings = defaultdict(lambda: defaultdict(list))
sensor_readings_processed = defaultdict(lambda: defaultdict(list))

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("coap-server")
logger.setLevel(logging.DEBUG)

NUMBER_OF_SENSORS = 3
Z_THRESHOLD = 1.960

async def decodeTemperature(site, reading, sensor):
    global sensor_readings
    processed_value = None
    is_outlier = False

    site_name = sites[site]

    reading = list(map(int, reading.strip().split(',')))
    logger.debug(f"Sensor reading: {reading}")

    reading, parity = reading[0], reading[1]

    if (parityCheck(reading, parity)):
        logger.debug(f"Initializing reading for site {site_name}")
        sensor_readings[site_name][sensor].append(reading)
    else:
        if 2 <= len(sensor_readings[site_name][sensor]):
            logger.debug(f"Mismatched{reading} {parity} {parityCheck(reading, parity)}" )
            prev_value = sensor_readings[site_name][sensor][-1]
            prev_prev_value = sensor_readings[site_name][sensor][-2]
            interpolated_value = (prev_value + prev_prev_value) / 2.0
            sensor_readings[site_name][sensor].append(interpolated_value)

    logger.debug(f"Sensor readings for site {site_name}:{sensor}:{len(sensor_readings[site_name][sensor])}")

    if len(sensor_readings[site_name][sensor]) > 3:
        logger.debug(f"Processing sensor readings for site {site_name}, sensor {sensor}")
        reading_for_processing = sensor_readings[site_name][sensor]
        logger.debug(f"Reading for processing: {reading_for_processing}")
        processed_value = filter_outliers(readings=np.array(reading_for_processing),
                                          z_threshold=Z_THRESHOLD)
        if processed_value is None:
            processed_value = sensor_readings[site_name][sensor].pop()
            is_outlier = True

    # Memory optimization
    if len(sensor_readings[site_name][sensor]) > NUMBER_OF_SENSORS * 3:
        logger.debug(f"Memory optimization for site {site_name}, sensor {sensor}")
        sensor_readings[site_name][sensor] = sensor_readings[site_name][sensor][-1:]

    return processed_value, is_outlier


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
    mean_reading = np.mean(readings[: -1])

    print(f"Mean = {int(mean_reading)}, {readings[: -1]}")  # Debugging

    # Calculate standard deviation of the readings
    std_dev_reading = np.std(readings[: -1])

    print(f"SD = {int(std_dev_reading)}")  # Debugging

    # Filtering outliers
    z_score = np.abs((readings[-1] - mean_reading) / std_dev_reading)

    lower_bound = mean_reading - z_threshold * std_dev_reading
    upper_bound = mean_reading + z_threshold * std_dev_reading

    logger.debug(f"Z score: {z_score} Mean: {mean_reading} SD: {std_dev_reading} Lower bound: {lower_bound} Upper bound: {upper_bound}")  # Debugging
    current_reading_value = readings[-1]
    if current_reading_value > lower_bound or current_reading_value < upper_bound:
        logger.debug("Value outside confidence interval, discarding.")  # Debugging
        return None

    return current_reading_value
