import logging
from filterpy.kalman import KalmanFilter
import numpy as np

from configuration import sites

kf = {}  # Set to None initially
base_value = 0
buffer = []
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("coap-server")
logger.setLevel(logging.DEBUG)

async def initializeKalmanFilter(initial_value):
    kf = KalmanFilter(dim_x=1, dim_z=1)
    kf.x = np.array([[initial_value]])
    kf.F = np.array([[1]])
    kf.H = np.array([[1]])
    kf.P = np.array([[10]])
    kf.R = np.array([[20]])
    kf.Q = np.array([[5]])
    return kf

async def decodeTemperature(site, message, isBaseValue):
    global kf
    global base_value
    global buffer

    data_out = []
    site_name = sites[site]

    message = list(map(int, message[:-1].strip().split(',')))
    logger.debug(f"Message {message}")

    if int(isBaseValue) == 1:
        base_value = message[0]

    if site_name not in kf.keys():
        # Initialize Kalman filter with the initial value from the first request
        logger.debug(f"Initializing Kalman filter for site {site_name}")
        initial_value = message[0] / 100.0
        kf[site_name] = await initializeKalmanFilter(initial_value)

    if int(isBaseValue) == 0 and len(buffer) == 0:
        return [], []
    
    for i in range(0, len(message), 2):
        value, parity = message[i], message[i + 1]

        if (parityCheck(value, parity)):
            value= (value + base_value)/100.0 if int(isBaseValue) == 0 else value/100.0
            data_out.append(value)
        else:
            if 2 < len(buffer):
                logger.debug(f"mismatched{value} {parity} {parityCheck(value, parity)}" )
                prev_value = buffer[-1] 
                prev_prev_value = buffer[-2]
                interpolated_value = (prev_value + prev_prev_value) / 2.0
                data_out.append(interpolated_value)

    # filtered_data, kf[site_name] = await kalmanfilter(np.array(data_out), kf[site_name])
    buffer.extend(data_out)
    return data_out, data_out

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

async def kalmanfilter(z, kf):

    output = np.zeros(z.shape[0])
    output[0] = kf.x[0][0]

    for i in range(z.shape[0]):
        y = z[i]
        kf.predict()
        kf.update(y)
        output[i] = kf.x[0][0]

    return output, kf