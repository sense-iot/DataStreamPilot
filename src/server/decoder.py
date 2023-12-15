import struct
from filterpy.kalman import KalmanFilter
import numpy as np

def decodeTemperature(message):
    data_out = []
    message = list(map(int, message[:-1].strip().split(',')))
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

    filtered_data = kalmanfilter(np.array(data_out), data_out[0])
    # filtered_data = kalmanfilter_numpy(np.array(data_out, data_out[0]))
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

def kalmanfilter(z, s):
    kf = KalmanFilter(dim_x=1, dim_z=1) 
    kf.x = np.array([[s]])
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

# with  numpy only
def kalmanfilter_numpy(z, s):
    initial_state = np.array([[s]])
    F = np.array([[1]])  # State transition matrix
    H = np.array([[1]])  # Measurement matrix
    P = np.array([[10]])  # State covariance matrix
    R = np.array([[20]])  # Measurement noise covariance matrix
    Q = np.array([[5]])   # Process noise covariance matrix

    num_measurements = len(z)
    num_states = initial_state.shape[0]

    x = initial_state
    output = np.zeros((num_measurements, num_states))

    for i in range(num_measurements):
        # Prediction step
        x_pred = np.dot(F, x)
        P_pred = np.dot(np.dot(F, P), F.T) + Q

        # Update step
        y = z[i] - np.dot(H, x_pred)
        S = np.dot(np.dot(H, P_pred), H.T) + R
        K = np.dot(np.dot(P_pred, H.T), np.linalg.inv(S))

        x = x_pred + np.dot(K, y)
        P = P_pred - np.dot(np.dot(K, H), P_pred)

        output[i] = x.flatten()

    flat_list = [item for sublist in output for item in sublist]

    return flat_list