%% Initiate variables
rat = 'Creampuff';
exp = 'uLED-Stimulation'; % Experiment name
track_perf = false;
beh_data = '.txt';

fprintf('Rat: %s \n', rat); % Print rat name to check

% Create Save Paths
[save_folder, ~, save_loc, ~, ~, ~] = CreateSavePaths(rat, exp, beh_data, track_perf);

% Stimulation variables
stim_loops = 10; % Number of stimulation loops (10 loops is default)
stim_num = 1; % number of stims per loop
stim_window = 4; % Loop size
srate = 20; % sampling rate of stim

NIDAQ_LEDs_chans = [1 2 3 37 38 5 39 6 40 41 42 43];
LEDs_id = 1:length(NIDAQ_LEDs_chans);
do_LEDs = DigitalOutput(NIDAQ_LEDs_chans);

%% Save Settings and Stim Information
date = num2str(yyyymmdd(datetime));
fID = fopen(save_loc,'wt');

fprintf(fID, 'Save Location: %s\n', save_loc);
fprintf(fID, 'Rat: %s\n', rat);
fprintf(fID, 'Experiment: %s\n', exp);
fprintf(fID, '%s \n', ['NIDAQ LED Channels: ', num2str(NIDAQ_LEDs_chans)]);
fprintf(fID, 'Number of Trials: %d\n', stim_loops);
fprintf(fID, 'Number of Stimulations per trial: %d\n', stim_num);
fprintf(fID, 'Stimulation Window: %ds\n', stim_window);
fprintf(fID, 'Sampling Rate: %dHz\n', srate);
fprintf(fID, 'Start Time: %s \n', string(datetime,'dd-MMM-yyyy hh:mm:ss:SSS'))

%% Stim stuff
r = rateControl(srate);
for cur_loop = 1:stim_loops
    tic;

    for cur_stim = 1:stim_num
        do_LEDs.Signal_Off_NI(LEDs_id);
        do_LEDs.toggleNI(LEDs_id, 0.01);
        time = r.TotalElapsedTime;
        disp(['Iteration: ', num2str(cur_loop), '- Time Elapsed: ',num2str(time)]);
    	fprintf(fID, 'Iteration: %d - Time Elapsed: %f\n', cur_loop,time);
        waitfor(r);
    end
    pause(stim_window-toc);
end
fprintf(fID, '\n');


%% 
fclose(fID);