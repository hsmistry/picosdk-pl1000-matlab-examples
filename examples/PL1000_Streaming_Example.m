%% PicoLog 1000 Series Data Logger Streaming Example
%
% This script demonstrates how to:
%
% * Open a connection to a PicoLog 1000 Series data logger
% * Display unit information
% * Turn off the trigger
% * Set the sampling interval
% * Take readings
% * Plot data
% * Close the connection to the unit
%
% Please refer to the
% <https://www.picotech.com/download/manuals/picolog-1000-series-data-loggers-programmers-guide.pdf PicoLog 1000 Series USB Data Loggers Programmer's Guide> for further information.
% This file can be edited to suit application requirements.
%
% *Copyright:* © 2012-2017 Pico Technology Ltd. See LICENSE file for terms.

%% Close any open figures, clear console window and workspace

close all;
clc;
clear;

disp('PicoLog 1000 Series Data Logger Streaming Example');

%% Load configuration information

PL1000Config;

%% Load shared library

% Indentify architecture and obtain function handle for the correct
% prototype file.
    
pl1000StreamingExample.archStr = computer('arch');

pl1000MFile = str2func(strcat('pl1000MFile_', pl1000StreamingExample.archStr));

if (~libisloaded('pl1000'))

	if ismac()
	   
		[pl1000NotFound, pl1000Warnings] = loadlibrary('libpl1000.dylib', pl1000MFile, 'alias', 'pl1000');
		
		% Check if the library is loaded
		if ~libisloaded('pl1000')
		
			error('PL1000StreamingExample:LibaryNotLoaded', 'Library libpl1000.dylib not loaded.');
		
		end
		
	elseif isunix()
		
		[pl1000NotFound, pl1000Warnings] = loadlibrary('libpl1000.so', pl1000MFile, 'alias', 'pl1000');
		
		% Check if the library is loaded
		if ~libisloaded('pl1000')
		
			error('PL1000StreamingExample:LibaryNotLoaded', 'Library libpl1000.so not loaded.');
		
		end
		
	elseif ispc()
		
		[pl1000NotFound, pl1000Warnings] = loadlibrary('pl1000.dll', pl1000MFile);
		
		% Check if the library is loaded
		if ~libisloaded('pl1000')
		
			error('PL1000StreamingExample:LibaryNotLoaded', 'Library pl1000.dll not loaded.');
		
		end
		
	else
		
		error('PL1000StreamingExample:OSNotSupported', 'Operating system not supported, please contact support@picotech.com');
		
	end
	
end

%% Open connection to device
% Open the unit - returns a handle to the device.

pl1000StreamingExample.pUnitHandle = libpointer('int16Ptr', 0);

pl1000StreamingExample.status.openUnit = calllib('pl1000', 'pl1000OpenUnit', pl1000StreamingExample.pUnitHandle);

if (pl1000StreamingExample.status.openUnit == PicoStatus.PICO_OK)
    
    pl1000StreamingExample.unitHandle = pl1000StreamingExample.pUnitHandle.Value;
    
else
    
    unloadlibrary('pl1000');
    error('PL1000StreamingExample:UnitNotFound', 'PicoLog 1000 Series device not found.');
    
end

%% Display unit information

fprintf('\nUnit information:\n\n');

pl1000StreamingExample.information = {'Driver version: ', 'USB Version: ', 'Hardware version: ', 'Variant: ', 'Batch/Serial: ', 'Cal. date: ', 'Kernel driver version: '};

pl1000StreamingExample.pRequiredSize = libpointer('int16Ptr', 0);

pl1000StreamingExample.status.unitInfo = zeros(length(pl1000StreamingExample.information), 1, 'uint32');

% Loop through each information type
for n = 1:length(pl1000StreamingExample.information)
    
    pl1000StreamingExample.infoLine = blanks(100);

    [pl1000StreamingExample.status.unitInfo(n), pl1000StreamingExample.infoLine1] = calllib('pl1000', 'pl1000GetUnitInfo', pl1000StreamingExample.unitHandle, ...
                                                                pl1000StreamingExample.infoLine, length(pl1000StreamingExample.infoLine), ...
                                                                pl1000StreamingExample.pRequiredSize, (n-1));
    
    if (pl1000StreamingExample.status.unitInfo(n) == PicoStatus.PICO_OK)
    
        disp([pl1000StreamingExample.information{n} pl1000StreamingExample.infoLine1]);
    
    else
    
        pl1000StreamingExample.status.closeUnit = calllib('pl1000', 'pl1000CloseUnit', pl1000StreamingExample.unitHandle);
        unloadlibrary('pl1000');
        error('PL1000StreamingExample:UnitInfo', 'Error calling pl1000GetUnitInfo - status code: %d.', pl1000StreamingExample.status.unitInfo(n));
    
    end
    
end

fprintf('\n');

%% Maximum ADC value
% Obtain the maximum ADC value for the device.

pl1000StreamingExample.pMaxValue = libpointer('uint16Ptr', 0);

pl1000StreamingExample.status.maxValue = calllib('pl1000', 'pl1000MaxValue', pl1000StreamingExample.unitHandle, pl1000StreamingExample.pMaxValue);

if (pl1000StreamingExample.status.maxValue == PicoStatus.PICO_OK)
    
    pl1000StreamingExample.maxValue = pl1000StreamingExample.pMaxValue.Value;
    
else
    
    pl1000StreamingExample.status.closeUnit = calllib('pl1000', 'pl1000CloseUnit', pl1000StreamingExample.unitHandle);
    unloadlibrary('pl1000');
    error('PL1000StreamingExample:MaxValue', 'Error calling pl1000MaxValue - status code: %d.', pl1000StreamingExample.status.maxValue);
    
end

%% Set trigger
% Set trigger to off.

pl1000StreamingExample.status.setTrigger = calllib('pl1000', 'pl1000SetTrigger', pl1000StreamingExample.unitHandle, 0, 0, 0, 0, 0, 0, 0, 0);

if (pl1000StreamingExample.status.maxValue ~= PicoStatus.PICO_OK)
    
    pl1000StreamingExample.status.closeUnit = calllib('pl1000', 'pl1000CloseUnit', pl1000StreamingExample.unitHandle);
    unloadlibrary('pl1000');
    error('PL1000StreamingExample:SetTrigger', 'Error calling pl1000SetTrigger - status code: %d.', pl1000StreamingExample.status.setTrigger);
    
end

%% Set sampling interval
% Set the sampling interval - parameters have been defined above.

pl1000StreamingExample.usForBlock           = 1000000;
pl1000StreamingExample.nSamples             = 4000;
pl1000StreamingExample.channels             = [pl1000Enuminfo.enPL1000Inputs.PL1000_CHANNEL_1, pl1000Enuminfo.enPL1000Inputs.PL1000_CHANNEL_2];
pl1000StreamingExample.nChannels            = length(pl1000StreamingExample.channels);
pl1000StreamingExample.nSamplesPerChannel   = pl1000StreamingExample.nSamples / pl1000StreamingExample.nChannels;

% Pointer to the number of microseconds per block
pl1000StreamingExample.pUsForBlock = libpointer('uint32Ptr', pl1000StreamingExample.usForBlock);

pl1000StreamingExample.status.samplingInterval = calllib('pl1000', 'pl1000SetInterval', pl1000StreamingExample.unitHandle, pl1000StreamingExample.pUsForBlock, ...
                            pl1000StreamingExample.nSamplesPerChannel, pl1000StreamingExample.channels, pl1000StreamingExample.nChannels);

if (pl1000StreamingExample.status.samplingInterval == PicoStatus.PICO_OK)
    
    pl1000StreamingExample.usForBlock = pl1000StreamingExample.pUsForBlock.Value;
    
else
    
    pl1000StreamingExample.status.closeUnit = calllib('pl1000', 'pl1000CloseUnit', pl1000StreamingExample.unitHandle);
    unloadlibrary('pl1000');
    error('PL1000StreamingExample:SetInterval', 'Error calling pl1000SamplingInterval - status code: %d.', pl1000StreamingExample.status.setInterval);
    
end                        

% Calculate the time interval being used in microseconds.
pl1000StreamingExample.timeIntervalUs  = pl1000StreamingExample.usForBlock / pl1000StreamingExample.nSamples;

% Convert to seconds. 
pl1000StreamingExample.timeInterval    = double(pl1000StreamingExample.timeIntervalUs) / 1e6; 

%% Start data collection and wait for data

pl1000StreamingExample.method = pl1000Enuminfo.BLOCK_METHOD.BM_STREAM;

pl1000StreamingExample.totalSamplesToCollectPerChannel  = 10000;
pl1000StreamingExample.totalSamplesPerChannel           = 0;

pl1000StreamingExample.pIsReady              = PicoConstants.FALSE;

% Data buffer to store data
pl1000StreamingExample.pBuffer              = libpointer('uint16Ptr', zeros(pl1000StreamingExample.nSamples, 1)); % Used to collect data


% Start device running
pl1000StreamingExample.status.run = calllib('pl1000', 'pl1000Run', pl1000StreamingExample.unitHandle, pl1000StreamingExample.nSamplesPerChannel, pl1000StreamingExample.method);

if (pl1000StreamingExample.status.samplingInterval == PicoStatus.PICO_OK)
    
    pl1000StreamingExample.usForBlock = pl1000StreamingExample.pUsForBlock.Value;
    
else
    
    pl1000StreamingExample.status.closeUnit = calllib('pl1000', 'pl1000CloseUnit', pl1000StreamingExample.unitHandle);
    unloadlibrary('pl1000');
    error('PL1000StreamingExample:Run', 'Error calling pl1000Run - status code: %d.', pl1000StreamingExample.status.setTrigger);
    
end       

 % Create a figure
figure1 = figure('Name','PicoLog 1000 Series Example - Streaming Mode Capture', 'NumberTitle','off');
axes1 = axes('Parent', figure1);

hold(axes1, 'on');
title(axes1, 'Voltage vs. Time')
xlabel(axes1, 'Time (\mus)')
ylabel(axes1, 'Voltage (mV)');
ylim(axes1, [0 2500]);
grid(axes1, 'on');

% Buffers to hold ch1 and ch2 values.

pl1000StreamingExample.ch1 = [];
pl1000StreamingExample.ch2 = [];
    
% Collect data until the total number of samples has been collected
while (pl1000StreamingExample.totalSamplesPerChannel < pl1000StreamingExample.totalSamplesToCollectPerChannel)
    
    pl1000StreamingExample.isReady  = PicoConstants.FALSE;
    pl1000StreamingExample.pReady   = libpointer('int16Ptr', PicoConstants.FALSE);
    
    % Wait for device to become ready
    while (pl1000StreamingExample.isReady == PicoConstants.FALSE)

        pl1000StreamingExample.status.ready = calllib('pl1000', 'pl1000Ready', pl1000StreamingExample.unitHandle, pl1000StreamingExample.pReady);
        
        if (pl1000StreamingExample.status.ready == PicoStatus.PICO_OK)
           
            pl1000StreamingExample.isReady = pl1000StreamingExample.pReady.Value;
            
        end
        
        pause(0.001);

    end

    pl1000StreamingExample.pNumSamplesPerChannel    = libpointer('uint32Ptr', pl1000StreamingExample.nSamplesPerChannel);
    pl1000StreamingExample.pOverflow                = libpointer('uint16Ptr', zeros(1,1));
    
    % Null value for trigger index as we are not using trigger capture.
    pl1000StreamingExample.triggerIndex = [];

    % Data buffer to store millivolt conversions into.
    pl1000StreamingExample.valuesMV = zeros(pl1000StreamingExample.nSamplesPerChannel, pl1000StreamingExample.nChannels);

    % Buffer to hold all the values together
    pl1000StreamingExample.valueMVBuffer = [];

    

    pl1000StreamingExample.status.getValues = calllib('pl1000', 'pl1000GetValues', pl1000StreamingExample.unitHandle, ...
                                                pl1000StreamingExample.pBuffer, pl1000StreamingExample.pNumSamplesPerChannel, ...
                                                pl1000StreamingExample.pOverflow, pl1000StreamingExample.triggerIndex);

    pl1000StreamingExample.samplesCollectedPerChannel = double(pl1000StreamingExample.pNumSamplesPerChannel.Value);
    
    % Calculate the total number of samples obtained
    pl1000StreamingExample.samplesCollected = pl1000StreamingExample.nChannels * pl1000StreamingExample.samplesCollectedPerChannel;


    if (pl1000StreamingExample.samplesCollectedPerChannel > 0)

        % Get the data
        pl1000StreamingExample.values = pl1000StreamingExample.pBuffer.Value;

        % Data buffer to extract individual channel readings into
        pl1000StreamingExample.channelValues = zeros(pl1000StreamingExample.samplesCollectedPerChannel, pl1000StreamingExample.nChannels);

        % Extract values
        for j = 1:pl1000StreamingExample.nChannels

            pl1000StreamingExample.channelValues(:, j) = double(pl1000StreamingExample.values(j:pl1000StreamingExample.nChannels:pl1000StreamingExample.samplesCollected, 1));

        end

        % Buffer contains data from each channel e.g. for 4 channels, data will be
        % in order [ch1, ch2, ch3, ch4, ch1, ch2, ch3, ch4, ch1,... etc.]

        % Convert data to millivolts
        pl1000StreamingExample.valuesMV = pl1000adc2mv(pl1000StreamingExample.channelValues, pl1000StreamingExample.maxValue);

        % Extract and concatenate millivolt values
        pl1000StreamingExample.valueMVBuffer = vertcat(pl1000StreamingExample.valueMVBuffer, pl1000StreamingExample.valuesMV(1:pl1000StreamingExample.samplesCollectedPerChannel, :));


        % Increment total number of samples
        pl1000StreamingExample.totalSamplesPerChannel = pl1000StreamingExample.totalSamplesPerChannel + pl1000StreamingExample.samplesCollectedPerChannel;

        % Extract data values and concatenate with previous values
        pl1000StreamingExample.ch1 = vertcat(pl1000StreamingExample.ch1, pl1000StreamingExample.valueMVBuffer(1:pl1000StreamingExample.samplesCollectedPerChannel, 1));
        pl1000StreamingExample.ch2 = vertcat(pl1000StreamingExample.ch2, pl1000StreamingExample.valueMVBuffer(1:pl1000StreamingExample.samplesCollectedPerChannel , 2));

        % Process data....


        % Plot data on figure

        % Time
        pl1000StreamingExample.t = ((0: double(pl1000StreamingExample.totalSamplesPerChannel * pl1000StreamingExample.nChannels) - 1)) .* double(pl1000StreamingExample.timeIntervalUs);

        % Time alternates between each channel so extract times
        pl1000StreamingExample.timeCh1 = pl1000StreamingExample.t(1:pl1000StreamingExample.nChannels:end);
        pl1000StreamingExample.timeCh2 = pl1000StreamingExample.t(2:pl1000StreamingExample.nChannels:end);

        plot(pl1000StreamingExample.timeCh1', pl1000StreamingExample.ch1, 'b', pl1000StreamingExample.timeCh2', pl1000StreamingExample.ch2, 'r')

    else

        disp('No values');

    end


    pause(0.1)

end

legend(axes1, 'ch1', 'ch2');
hold(axes1, 'off');

%% Stop the device

pl1000StreamingExample.statusStop = calllib('pl1000', 'pl1000Stop', pl1000StreamingExample.unitHandle);

%% Close the connection to the unit
% Close the connection to the unit and unload the shared library.

pl1000StreamingExample.status.closeUnit = calllib('pl1000', 'pl1000CloseUnit', pl1000StreamingExample.unitHandle);
unloadlibrary('pl1000');