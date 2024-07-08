pumpOpen = 0.10;

% NIDAQ Inputs
NIDAQ_sensor_chans = [51 17];
sensors = 1:length(NIDAQ_sensor_chans);

% NIDAQ Outputs
NIDAQ_solenoid_chans = [10 11];
valves = 1:length(NIDAQ_solenoid_chans);

% To read inputs from 16 sensors on NI board and output to up to 4 solenoids
di = DigitalInput(NIDAQ_sensor_chans);
disp('Successfully Initiated Digital Input: di_sensors.');

do = DigitalOutput(NIDAQ_solenoid_chans);
disp('Successfully Initiated Digital Output: do_solenoids.');

do.toggleNI(valves, pumpOpen);
