%% Initiate variables
rat = 'Mocha'; % rat name
fprintf('Rat: %s \n', rat); % Print rat name to check

% Experiment & Save location
exp = 'Opto_Stim'; % Experiment name



% Stimulation variables
stim_loops = 10; % Number of stimulation loops (10 loops is default)
stim_num = 1; % number of stims per loop
stim_window = 4; % Loop size
srate = 20; % sampling rate of stim

NIDAQ_LEDs_chans = [1 2 3 37 38 5 39 6 40 41 42 43];
LEDs_id = 1:length(NIDAQ_LEDs_chans);
do_LEDs = DigitalOutput(NIDAQ_LEDs_chans);



% %% Stim stuff
r = rateControl(srate);
for cur_loop = 1:stim_loops
    tic;

    for cur_stim = 1:stim_num
        do_LEDs.Signal_Off_NI(LEDs_id);
        do_LEDs.toggleNI(LEDs_id, 0.01);
        time = r.TotalElapsedTime;
    	fprintf('Iteration: %d - Time Elapsed: %f\n', cur_loop,time)
        waitfor(r);
    end
    pause(stim_window-toc);
end
