function [] = Water_Training_BK()


%% Initial Parameters
rat = 'Mocha';

% Print rat name to check if you're running the correct rat
fprintf('Rat: %s \n', rat)

% In seconds, length of time water is delivered (small because of the gravity system)
% don't go lower than 0.02! solenoid won't work. sometimes unreliable up to 0.07 as well.
pumpOpen = 0.10;
starttime = datetime;
t = replace(char(timeofday(starttime)),':','.');


% Get save location from user and create  water performance directory if it does not exist.
exp = 'Water-Training'; % Experiment name
[~, ~, ~, waterlog_folder, waterlog_filename, waterlog_filepath] = CreateSavePaths(rat, exp);
disp(['Save Folder: ' waterlog_folder]);
disp(['Save Filepath: ' waterlog_filepath]);
fID = fopen(waterlog_filepath,'a');



%% Initialize figure for water performance
performance_fig = figure;
title('Overall Performance') % how often they go to the specific required port
xlabel('Minutes from start')
ylabel('Performance')
hold all
hold on


%% NIDAQ Parameters
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


%% Create cleanup obj to save figs + close file upon ctrl+c
cleanup = onCleanup(@()myCleanupFun(waterlog_folder, performance_fig,fID,rat));


%% Prefill wells
do.toggleNI(valves, pumpOpen);


%% RUN
disp('Starting water training')
lastSensor = 0;
lastCorrect = 0;
performanceVec = [];
n = 1;
newsensortime = [];
tri = 0;


while true

    drawnow;
    port = di.readNI; % default is zero if it's not being triggered, one if it is.
    activeport=find(port==1);

    if isempty(activeport)
        activeport = 0;
        continue
    end

    %% Port 1 triggered

    %%%% first port in session
    %identify if it's a repeat port
    if activeport == lastSensor
        repeat = 1;
    else
        repeat = 0;
        newsensortime = datetime;
    end

    %%%% water trigger rules
    if activeport == sensors(1) && lastCorrect == 0
        do.toggleNI(valves(2),pumpOpen) % output,time(seconds)
        lastCorrect = sensors(1);
        firstport = sensors(1);
        outcome = 1;
        %%%% triggered and correct
    elseif activeport == sensors(1) && lastCorrect == sensors(2)
        do.toggleNI(valves(2),pumpOpen) % output,time(seconds)
        lastCorrect = sensors(1);
        outcome = 1;
        %%%% triggered but wrong
    elseif activeport == sensors(1) && lastCorrect ~= 0 && lastCorrect ~= sensors(2)
        outcome = 0;

        %% Port 2 triggered
        %%%% first port in session
    elseif activeport == sensors(2) && lastCorrect == 0
        do.toggleNI(valves(1),pumpOpen) % output,time(seconds)
        lastCorrect = sensors(2);
        firstport = sensors(2);
        outcome = 1;

        %%%% triggered and correct
    elseif activeport == sensors(2) && lastCorrect == sensors(1)
        do.toggleNI(valves(1),pumpOpen) % output,time(seconds)
        lastCorrect = sensors(2);
        outcome = 1;

        %%%% triggered but wrong
    elseif activeport == sensors(2) && lastCorrect ~= 0 && lastCorrect ~= sensors(1)
        outcome = 0;

        %% Any other ports triggered

    elseif activeport ~= sensors(1) && activeport ~= sensors(2) ...
            && activeport ~= 0
        outcome = 0;
    end

    lastSensor = activeport;

    %% Calculate general performance
    d = datetime;
    if repeat == 0 || seconds(d-newsensortime)>= 15 % %if at least 15 seconds since the rat initiated new sensor visit
        if repeat == 1
            newsensortime = datetime;
        end

        performanceVec(n) = outcome;
        if n <10
            performance = sum(performanceVec)/length(performanceVec);
        else
            performance = sum(performanceVec(n-9:n))/10;
        end
        scatter(minutes(d-starttime),performance)
        disp(['Performance = ' num2str(performance)])

        drawnow; % to force fig update

        n = n + 1;
        %% Write to file and send to open ephys

        %if seconds(d-lastPrintTime) >= 5 % if at least 5 seconds since the last print time
        fprintf(fID,' %s %d %i \n', string(d,'dd-MMM-yyyy hh:mm:ss:SSS'), activeport, performance); %then write to file
        lastPrintTime = datetime; lastPrintTime.Format = 'hh:mm:ss:SSS';

        % send to open ephys
        %end

        if outcome == 1 && activeport ~= firstport % just to print # of trials
            tri = tri + 1;
            disp(['Trial ' num2str(tri) ' complete'])
        end

    end %  if repeat == 0 || seconds(d-newsensortime)>= 15
end 


end % Alternating_Water_BK.m


%% Helper Functions--------------------------------------------------------------------------------%
function myCleanupFun(waterlog_folder, h,fID,rat)
% so when ctrl+c it closes the file and saves the figures
fclose(fID);
d = datetime;
saveas(h, fullfile(waterlog_folder, [rat, '_', char(d,'dd-MMM-yyyy_hh.mm.ss.SSS') '_performance.fig']))
saveas(h, fullfile(waterlog_folder, [rat, '_', char(d,'dd-MMM-yyyy_hh.mm.ss.SSS') '_performance.pdf']))
disp('Files and figures saved') %if you close fig before saving you'll get saveas error
end
