import struct
from filterpy.kalman import KalmanFilter
import numpy as np

kf = None  # Set to None initially

def initializeKalmanFilter(initial_value):
    global kf
    kf = KalmanFilter(dim_x=1, dim_z=1)
    kf.x = np.array([[initial_value]])
    kf.F = np.array([[1]])
    kf.H = np.array([[1]])
    kf.P = np.array([[10]])
    kf.R = np.array([[10]])
    kf.Q = np.array([[5]])

def decodeTemperature(message):
    global kf
    data_out = []

    message = list(map(int, message[:-1].strip().split(',')))

    if kf is None:
        # Initialize Kalman filter with the initial value from the first request
        print("Initializing Kalman filter")
        initial_value = message[0] / 100.0
        initializeKalmanFilter(initial_value)

    for i in range(0, len(message), 2):
        value, parity = message[i], message[i + 1]
        if i == 0:
            base_value = value
            data_out.append(value/100)
            continue
        if (parityCheck(value, parity)):
            message[i] = (message[i] + base_value)/100.0
            data_out.append(message[i])
        else:
            if 0 < i and i + 2 < len(message):
                prev_value = message[i - 2] + base_value
                next_value = message[i + 2] + base_value
                interpolated_value = (prev_value + next_value) // 2 if i != 2 else (prev_value + message[i + 2] + base_value) // 2
                data_out.append(interpolated_value / 100.0)

    filtered_data = kalmanfilter(np.array(data_out), kf).tolist()
    # filtered_data = []
    return data_out, filtered_data

#checking odd parity
def calculate_odd_parity(num):
    count = 0
    for i in range(16):  # Assuming 16-bit integers
        if num & 1:
            count += 1
        num >>= 1
    return 1 if count % 2 == 0 else 0

def parityCheck(value, parity):
    ones_count = calculate_odd_parity(value)
    return (ones_count + int(parity)) % 2 == 1

def kalmanfilter(z, kf):

    output = np.zeros(z.shape[0])
    # output[0] = kf.x[0][0]

    for i in range(z.shape[0]):
        y = z[i]
        kf.predict()
        kf.update(y)
        output[i] = kf.x[0][0]

    return output