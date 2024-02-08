% Number of sensor readings
numReadings = 10000;

% Sensor reading (fixed value)
sensorReading = 39.456;

% Standard deviation for noise
stddev = 7.892;  % Adjust this value based on your requirements

% Array to store noisy readings
noisyReadings = zeros(1, numReadings);

% Generate noisy sensor readings
for i = 1:numReadings
    noisyReadings(i) = sensorReading + add_noise(stddev);
end

maxi = max(noisyReadings);
mini = min(noisyReadings);
fprintf('Maximum Value: %f\n', maxi);
fprintf('Minimum Value: %f\n', mini);

deviation_factor = 2;

Fs = 1000;
Y = fft(noisyReadings);
P2 = abs(Y/length(noisyReadings));
P1 = P2(1:length(noisyReadings)/2+1);
P1(2:end-1) = 2*P1(2:end-1);

f = Fs*(0:(length(noisyReadings)/2))/length(noisyReadings);

plot(f, P1) 
title('Single-Sided Amplitude Spectrum of X(t)')
xlabel('Frequency (f)')
ylabel('|P1(f)|')