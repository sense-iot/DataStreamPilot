function noise_val = add_noise(stddev)
    % Generate a random number between 1 and 100
    num = randi([1, 100], 1, 1); 

    if num >= 50
        % Generate a random number with normal distribution based on stddev
        noise_val = generate_normal_random(stddev);
    else
        noise_val = 0;
    end
end
