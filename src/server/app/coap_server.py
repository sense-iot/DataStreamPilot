import datetime
import logging
import json
import asyncio

import aiocoap.resource as resource
from aiocoap.numbers.contentformat import ContentFormat
import aiocoap
import numpy as np
from collections import defaultdict
from configuration import sites
from database import client, getInfluxDB, sendInfluxdb
from configuration import TEMPERATURE

from decoder import decodeTemperature

# logging setup
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("coap-server")
logger.setLevel(logging.DEBUG)

class TimeResource(resource.ObservableResource):
    async def render_get(self, request):
        payload = datetime.datetime.now().\
                strftime("%Y-%m-%d %H:%M").encode('ascii')
        return aiocoap.Message(payload=payload)

WINDOW_SIZE = 65
Z_THRESHOLD = 1.960

class Temperature(resource.Resource):
    def __init__(self):
        self.site_data = {
        'grenoble': {
            '1': {'values': [0] * WINDOW_SIZE, 'index': 0},
            '2': {'values': [0] * WINDOW_SIZE, 'index': 0},
            '3': {'values': [0] * WINDOW_SIZE, 'index': 0}
        },
        'strasbourg': {
            '1': {'values': [0] * WINDOW_SIZE, 'index': 0},
            '2': {'values': [0] * WINDOW_SIZE, 'index': 0},
            '3': {'values': [0] * WINDOW_SIZE, 'index': 0}
        },
        'saclay': {
            '1': {'values': [0] * WINDOW_SIZE, 'index': 0},
            '2': {'values': [0] * WINDOW_SIZE, 'index': 0},
            '3': {'values': [0] * WINDOW_SIZE, 'index': 0}
        },
        'lillie': {
            '1': {'values': [0] * WINDOW_SIZE, 'index': 0},
            '2': {'values': [0] * WINDOW_SIZE, 'index': 0},
            '3': {'values': [0] * WINDOW_SIZE, 'index': 0}
        }
    }
        self.logger = logging.getLogger("temperature")
    
    async def render_post(self, request):
        payload = json.loads(request.payload.decode('utf8'))
        logger.debug(f"\nReceived message: {payload}")

        site_name = sites[payload['site']]
        sensor = payload['sensor']
        sensor_reading = payload['value']

        reading = list(map(int, sensor_reading.strip().split(',')))
        self.logger.debug(f"Sensor reading: {reading}")
        sensor_value, parity = reading[0], reading[1]

        if (self.parityCheck(sensor_value, parity)):
            self.logger.debug(f"Initializing reading for site {site_name}")
            self.site_data[site_name][sensor]['values'][self.site_data[site_name][sensor]['index']] = sensor_value
        else:
            if 2 <= len(self.site_data[site_name]['values']):
                self.logger.debug(f"Mismatched{reading} {parity} {self.parityCheck(reading, parity)}" )
                prev_value = self.site_data[site_name][sensor]['values'][-1]
                self.site_data[site_name][sensor]['values'][self.site_data[site_name][sensor]['index']] = prev_value

        self.site_data[site_name][sensor]['index'] = (self.site_data[site_name][sensor]['index'] + 1) % WINDOW_SIZE

        sensor1 = self.site_data[site_name]['1']['values'][-1]
        sensor2 = self.site_data[site_name]['2']['values'][-1]
        sensor3 = self.site_data[site_name]['3']['values'][-1]

        zscore_analysis_list = [sensor1, sensor2, sensor3]
        decodedValue = self.filter_outliers(readings=np.array(zscore_analysis_list), z_threshold=Z_THRESHOLD)
        if decodedValue is None:
            decodedValue = self.site_data[site_name][sensor]['values'][-1]
            is_outlier = True
        
        self.logger.debug(f"Sensor readings for site {site_name}:{sensor}:{len(self.site_data[site_name][sensor]['values'])}")
        self.logger.debug(f"Decoded values: {decodedValue} {is_outlier}")

        if decodedValue != None:
            recordedFlag = await sendInfluxdb(decodedValue, is_outlier, payload['site'], payload['sensor'])
            logger.debug(f"Recorded flag: {recordedFlag}\n")

        return aiocoap.Message(content_format=0,
                payload=json.dumps({"status": "OK"}).encode('utf8'))
    
    def filter_outliers(self, readings, z_threshold):
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
        if current_reading_value > lower_bound and current_reading_value < upper_bound:
            logger.debug("Value is in the confidence interval.")  # Debugging
            return current_reading_value
        logger.debug("Value outside the confidence interval. Value Disregarded!")  # Debugging
        return None

    def calculate_odd_parity(self, num):
        count = 0
        for i in range(16):  # Assuming 16-bit integers
            if num & 1:
                count += 1
            num >>= 1
        return count

    def parityCheck(self, value, parity):
        ones_count = self.calculate_odd_parity(value)
        return (ones_count + int(parity)) % 2 == 1

async def handle_requests():
    root = resource.Site()
    root.add_resource(['time'], TimeResource())
    root.add_resource(['temp'], Temperature())

    context = await aiocoap.Context.create_server_context(root, bind=('::', 5683))
    logger.info("Server started on ('::', 5683)")

    try:
        while True:
            await asyncio.sleep(3600)  # Sleep for 1 hour or adjust as needed
    except asyncio.CancelledError:
        pass
    finally:
        await context.shutdown()

async def main():
    await asyncio.gather(handle_requests())

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
    except Exception as e:
        print(f"Error: {e}")
