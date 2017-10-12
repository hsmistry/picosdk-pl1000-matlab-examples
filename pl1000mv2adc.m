function adcCounts = pl1000mv2adc(values, maxValue)
%PL1000ADC2MV Converts millivolt value to ADC count for PicoLog 1000 series
%   values - value(s) to be converted (millivolts)
%   maxValue - maximum ADC count of the device
%
% See also pl1000adc2mv.
%
% Copyright © 2012-2017 Pico Technology Ltd. See LICENSE file for terms.

    % Validate input parameters.
    validateattributes(values, {'numeric'}, {'real', 'finite', 'nonnegative', 'nonnan'});
    validateattributes(maxValue, {'numeric'}, {'scalar', 'integer', 'positive'});
    
    % Convert data.
    adcCounts = (values * double(maxValue)) ./ 2500;

end