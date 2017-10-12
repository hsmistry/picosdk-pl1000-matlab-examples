function millivolts = pl1000adc2mv(values, maxValue)
%PL1000ADC2MV Converts milliVolt value to ADC count for PicoLog 1000 series
%   values - raw ADC value(s)
%   maxValue - maximum ADC count of the device
%
% See also pl1000mv2adc.
%
% Copyright © 2012-2017 Pico Technology Ltd. See LICENSE file for terms.

    % Validate input parameters.
    validateattributes(values, {'numeric'}, {'real', 'finite', 'nonnegative', 'nonnan'});
    validateattributes(maxValue, {'numeric'}, {'scalar', 'integer', 'positive'});
    
    % Convert raw data.
    millivolts = (double(values) * 2500 ./ maxValue);

end