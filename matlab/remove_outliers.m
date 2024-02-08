function cleanedReadings = remove_outliers(noisyReadings, windowSize, deviation_factor)
    % Apply moving average filter
    filteredReadings = movmean(noisyReadings, windowSize);
    mean_val = mean(noisyReadings);
    std_dev = std(filteredReadings); 
    % Calculate deviation threshold
    deviation_threshold = deviation_factor * std_dev;

    % Identify values that are within the acceptable range
    is_good_value = abs(noisyReadings - mean_val) < deviation_threshold;

    % Keep only good values
    cleanedReadings = noisyReadings(is_good_value);
end