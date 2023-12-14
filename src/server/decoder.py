import struct
from filterpy.kalman import KalmanFilter
import numpy as np

def decodeTemperature(message):
    data_out = []
    message = list(map(int, message[:-1].strip().split(',')))
    data_out = message[:-1]
    print(data_out)
    base_value = data_out[0]
    for i, val in enumerate(data_out, start=1):
        data_out[i] = (data_out[i] + base_value)/100.0

    filtered_data = kalmanfilter(np.array(data_out))
    # for i in range(0, len(message), 2):
    #     value, parity = message[i], message[i + 1]
    #     if (parityCheck(value, parity)):
    #         data_out.append(value/100)
    #     else:
    #         if 0 < i and i + 2 < len(message):
    #             prev_value, next_value = message[i - 2], message[i + 2]
    #             interpolated_value = (prev_value + next_value) // 2
    #             data_out.append(interpolated_value)
    return filtered_data

#checking odd parity
def parityCheck(value, parity):
    ones_count = bin(int(value)).count('1')
    return (ones_count + int(parity)) % 2 == 1

def kalmanfilter(z):
    kf = KalmanFilter(dim_x=1, dim_z=1) 
    kf.x = np.array([[z[0]]])
    kf.F = np.array([[1]])
    kf.H = np.array([[1]])
    kf.P = np.array([[10]])
    kf.R = np.array([[20]])
    kf.Q = np.array([[5]])

    output = np.zeros(z.shape[0])
    output[0] = kf.x[0][0]

    for i in range(z.shape[0]):
        y = z[i]
        kf.predict()
        kf.update(y)
        output[i] = kf.x[0][0]

    return output