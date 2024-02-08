%
% r - accuracy (5%), 
% s - standard deviation, 
% x - Average, 
% z = 1.960 (95%) - TAKE THE CEIL
%

temp_mean = 39.456;
temp_stddev = 7.892;

windowSize = ((100 * 1.960 * temp_stddev) / (5*temp_mean))^2

