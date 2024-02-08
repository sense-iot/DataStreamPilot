function z = generate_normal_random(stddev)
    % Box-Muller transform to generate random numbers with normal distribution
    u1 = rand();
    u2 = rand();
    z = sqrt(-2 * log(u1)) * cos(2 * pi * u2);
    
    z = stddev * z;
end