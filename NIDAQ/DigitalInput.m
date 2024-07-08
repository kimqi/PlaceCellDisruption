classdef DigitalInput
    %DIGITALINPUT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Device
        NumberOfChannels
    end
    
    methods
        function obj = DigitalInput(chans)
            d = daqlist("ni");                                             % Grab NIDAQ Board information
            deviceInfo = d{1, "DeviceInfo"};                               % Grab device information from d object
            
            dq = daq("ni");                                                % Get NIDAQ Data Acquisition Information
            obj.Device=dq;                                                 % obj.Device set as dq
            
            DigitalIO=deviceInfo.Subsystems(3);                            % Set DigitalIO explicitly as digital acquisition, not analog or counterinput
            
            chans = NIDAQ_Channel_Interface(chans);                        %  Get input channels from NIDAQ Board and convert to MATLAB
            
            % Add channels to device info
            for ichan=chans
                cn=DigitalIO.ChannelNames{ichan};
                addinput(dq, deviceInfo.ID, cn, "Digital");
            end

            %assigning values to class properties 
            obj.NumberOfChannels=numel(chans);
        end
        
        function d = readNI(obj,num)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            d=read(obj.Device,1,"OutputFormat","Matrix");
            if exist("num","var")
                d=d(num);
            end
        end
    end
end

