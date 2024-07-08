%% Script for filling wells when the lines are empty

% NIDAQ Outputs
NIDAQ_solenoid_chans = [10 11];
solenoid_id = 1:length(NIDAQ_solenoid_chans);
do_solenoids = DigitalOutput(NIDAQ_solenoid_chans);



% Fill wells
duration = 0.1;
do_solenoids.toggleNI(solenoid_id,duration);

