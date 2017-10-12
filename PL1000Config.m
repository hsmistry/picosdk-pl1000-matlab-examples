%% PL1000Config Configure path information
% Configures paths according to platforms and loads information from
% prototype files for PicoLog 1000 Series data loggers. The folder 
% that this file is located in must be added to the MATLAB path.
%
% Platform Specific Information:-
%
% Microsoft Windows: Download the Software Development Kit installer from
% the <a href="matlab: web('https://www.picotech.com/downloads')">Pico Technology Download software and manuals for oscilloscopes and data loggers</a> page.
% 
% Linux: Follow the instructions to install the libpl1000 package from the <a href="matlab:
% web('https://www.picotech.com/downloads/linux')">Pico Technology Linux Software & Drivers for Oscilloscopes and Data Loggers</a> page.
%
% Apple Mac OS X: Follow the instructions to install the PicoScope 6
% application from the <a href="matlab: web('https://www.picotech.com/downloads')">Pico Technology Download software and manuals for oscilloscopes and data loggers</a> page.
% Optionally, create a 'maci64' folder in the same directory as this file
% and copy the following files into it:
%
% * libpl1000.dylib and any other libpl1000 library files
%
% Contact our Technical Support team via the <a href="matlab: web('https://www.picotech.com/tech-support/')">Technical Enquiries form</a> for further assistance.
%
% Run this script in the MATLAB environment prior to connecting to the 
% device.
%
% This file can be edited to suit application requirements.


%% Set path to shared libraries
% Set paths to shared library files according to the operating system and
% architecture.

% Identify working directory.
pl1000ConfigInfo.workingDir = pwd;

% Find file name.
pl1000ConfigInfo.configFileName = mfilename('fullpath');

% Only require the path to the config file.
[pl1000ConfigInfo.pathStr] = fileparts(pl1000ConfigInfo.configFileName);

% Identify architecture e.g. 'win64'.
pl1000ConfigInfo.archStr = computer('arch');

try

    addpath(fullfile(pl1000ConfigInfo.pathStr, pl1000ConfigInfo.archStr));
    
catch err
    
    error('PL1000Config:OperatingSystemNotSupported', 'Operating system not supported - please contact support@picotech.com');
    
end

% Set the path according to operating system.

if (ismac())
    
    % Libraries (including wrapper libraries) are stored in the PicoScope
    % 6 App folder. Add locations of library files to environment variable.
    
    setenv('DYLD_LIBRARY_PATH', '/Applications/PicoScope6.app/Contents/Resources/lib');
    
    if (contains(getenv('DYLD_LIBRARY_PATH'), '/Applications/PicoScope6.app/Contents/Resources/lib'))
       
        addpath('/Applications/PicoScope6.app/Contents/Resources/lib');
        
    else
        
        warning('PL1000Config:LibraryPathNotFound','Locations of libraries not found in DYLD_LIBRARY_PATH');
        
    end
     
elseif (isunix())
	    
    % Edit to specify location of .so files or place .so files in same
    % directory.
    addpath('/opt/picoscope/lib/'); 
		
elseif (ispc())
    
    % Microsoft Windows operating systems.
    
    % Set path to dll files if the Pico Technology SDK Installer has been
    % used or place dll files in the folder corresponding to the
    % architecture. Detect if 32-bit version of MATLAB on 64-bit Microsoft
    % Windows.
    
    pl1000ConfigInfo.winSDKInstallPath = '';
    
    if(strcmp(pl1000ConfigInfo.archStr, 'win32') && exist('C:\Program Files (x86)\', 'dir') == 7)
       
        try 
            
            addpath('C:\Program Files (x86)\Pico Technology\SDK\lib\');
            pl1000ConfigInfo.winSDKInstallPath = 'C:\Program Files (x86)\Pico Technology\SDK';
            
        catch err
           
            warning('PL1000Config:DirectoryNotFound', ['Folder C:\Program Files (x86)\Pico Technology\SDK\lib\ not found. '...
                'Please ensure that the location of the library files are on the MATLAB path.']);
            
        end
        
    else
        
        % 32-bit MATLAB on 32-bit Windows or 64-bit MATLAB on 64-bit
        % Windows operating systems.
        try 
        
            addpath('C:\Program Files\Pico Technology\SDK\lib\');
            pl1000ConfigInfo.winSDKInstallPath = 'C:\Program Files\Pico Technology\SDK';
            
        catch err
           
            warning('PL1000Config:DirectoryNotFound', ['Folder C:\Program Files\Pico Technology\SDK\lib\ not found. '...
                'Please ensure that the location of the library files are on the MATLAB path.']);
            
        end
        
    end
    
else
    
    error('PL1000Config:OperatingSystemNotSupported', 'Operating system not supported - please contact support@picotech.com');
    
end

%% Load enumerations and structure information
% Enumerations and structures are used by certain shared library functions.

% Find prototype file names based on architecture.
pl1000ConfigInfo.pl1000MFile = str2func(strcat('pl1000MFile_', pl1000ConfigInfo.archStr));
[pl1000Methodinfo, pl1000Structs, pl1000Enuminfo, pl1000ThunkLibName] = pl1000ConfigInfo.pl1000MFile(); 
