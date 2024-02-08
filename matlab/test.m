clc;clear;close all;

% Number of sensor readings
numReadings = 1000;

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

% Apply a simple moving average filter
windowSize = 65; % Adjust the window size as needed
deviation_factor = 2.0;

filteredReadings = movmean(noisyReadings, windowSize);
cleanedReadings = remove_outliers(noisyReadings, windowSize, deviation_factor);

fprintf('Original Maximum Value: %f\n', max(noisyReadings));
fprintf('Original Minimum Value: %f\n', min(noisyReadings));
fprintf('Original STD dev Value: %f\n', std(noisyReadings));
fprintf('Original mean Value: %f\n', mean(noisyReadings));
fprintf('Range Value: %f\n', max(noisyReadings) - min(noisyReadings));
fprintf('\n');

fprintf('Averaged Value: %f\n', max(filteredReadings));
fprintf('Averaged Minimum Value: %f\n', min(filteredReadings));
fprintf('Averaged STD dev Value: %f\n', std(filteredReadings));
fprintf('Averaged mean Value: %f\n', mean(filteredReadings));
fprintf('Range Value: %f\n', max(filteredReadings) - min(filteredReadings));
fprintf('\n');

fprintf('Cleaned Maximum Value: %f\n', max(cleanedReadings));
fprintf('Cleaned Minimum Value: %f\n', min(cleanedReadings));
fprintf('Cleaned STD dev Value: %f\n', std(cleanedReadings));
fprintf('Cleaned mean Value: %f\n', mean(cleanedReadings));
fprintf('Range Value: %f\n', max(cleanedReadings) - min(cleanedReadings));
fprintf('\n');

cleanedFiltered = movmean(cleanedReadings, windowSize);

fprintf('Cleaned Outliers Removed Maximum Value: %f\n', max(cleanedFiltered));
fprintf('Cleaned Outliers Removed Minimum Value: %f\n', min(cleanedFiltered));
fprintf('Cleaned Outliers Removed STD dev Value: %f\n', std(cleanedFiltered));
fprintf('Cleaned Outliers Removed mean Value: %f\n', mean(cleanedFiltered));
fprintf('Range Value: %f\n', max(cleanedFiltered) - min(cleanedFiltered));
fprintf('\n')

[dd,ran] = size(cleanedFiltered);
% Plot the results
figure;
plot(1:numReadings, noisyReadings, 'g-', 'DisplayName', 'Noisy Readings');
hold on;
plot(1:numReadings, filteredReadings, 'b-', 'LineWidth', 2, 'DisplayName', 'Filtered Readings');
plot(1:ran, cleanedFiltered, 'r-', 'LineWidth', 2, 'DisplayName', 'Final Readings');
legend show;
xlabel('Reading Number');
ylabel('Sensor Value');
title('Sensor Readings with Noise and Filtered Data');
hold off

figure;
hold on;
histogram(noisyReadings)
legend show;
hold off

figure;
hold on;
histogram(cleanedReadings)
histogram(cleanedFiltered)
title('Histograms of outlier removed data');
legend show;
ylim([0 140])
legend show;
hold off

figure;
histogram(cleanedFiltered)
title('Final data');
legend show;
legend show;
hold off