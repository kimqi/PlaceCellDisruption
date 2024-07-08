classdef DigitalOutput
    % Class Definition for NIDAQ Output to external systems
    
    % Properties
    properties
        VoltageRange             
        SamplingRate
        NumberOfChannels
        WriteToChanArray
        Device
    end
    
    %define methods of class - functions that implement class methods
    methods

        %sets the scanning rate of a class instance
        function obj = DigitalOutput(chans)
            d = daqlist("ni");
            deviceInfo = d{1, "DeviceInfo"};
            dq = daq("ni");
            
            % Check to make sure we have enough input arguments to initialize function
            if nargin < 1
                error('Not enough arguments, need output channels to map.')
            end

            obj.Device = dq;           
            DigitalIO=deviceInfo.Subsystems(3);

            % Convert channels from NIDAQ Board to MATLAB channels
            chans = NIDAQ_Channel_Interface(chans);

            % Map NIDAQ Channels to MATLAB channels
            for ichan=chans
                cn = DigitalIO.ChannelNames{ichan};
                addoutput(dq, deviceInfo.ID, cn, "Digital");
            end

            %Assign values to class properties
            obj.NumberOfChannels = numel(chans);
            obj.SamplingRate = dq.Rate;
            obj.WriteToChanArray = zeros(1,obj.NumberOfChannels);
        end
        
        %Write Function
        function [] = write(obj, points)
            % Writes to acquisition device object
            % MxN Matrix, where M is the number of scans (not important in this context at the moment)
            % N is the number of output channels.
            write(obj.Device, points);
        end

        % Toggle Signal
        function [] = toggleNI(obj, eventPin, dur)
            % Toggle signal to target output channel
            % obj is taken in by default
            % numchans = number of output signals in the object
            % eventPin = Channel in MATLAB format for output signal to occur
            % dur = signal ON time in seconds

            if ~exist('dur','var')
                disp('No duration input, using default of 100ms impulse.')
                dur=.100;                                                                           % Default duration: 100ms
            end
            
            chans = obj.WriteToChanArray;
            % Toggle
            chans(eventPin) = 1;                                                                    % Set pin to 1
            obj.Device.write(chans);                                                                % Write to device the pin to toggle on
            pause(dur);                                                                             % Pause duration in seconds from dur
            chans(eventPin) = 0;                                                                    % Set pin to 0
            obj.Device.write(chans);                                                                % Write to device the pin to toggle off
        end

        % Turn on signal for designated pin
        function [] = Signal_On_NI(obj, eventPin)
            % Turn signal ON
            chans = obj.WriteToChanArray;
            chans(eventPin) = 1;
            obj.Device.write(chans);
        end

        % Turn off signal for designated pin
        function [] = Signal_Off_NI(obj, eventPin)
            chans = obj.WriteToChanArray;
            % Turn Signal OFF
            chans(eventPin) = 0;
            obj.Device.write(chans);
        end
    end
end

