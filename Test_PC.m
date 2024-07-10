function [] = Place_Cell_Disruption_BK()
%% Function for Closed Loop Optogenetic Stimulation & Water Delivery System
% 
% Brian Kim, Nathaniel Kinsky 2024
%
% Uses OSC1Lite with a NIDAQ Board

%% Input Parameters
rat = 'Testing';
exp = 'Place-Cell-Disruption'; % Experiment name

stim_proportion = 0.8;
debug_mode = false;


disp(['Current Rat: ' rat]);
disp(['Stim Proportion: ' num2str(stim_proportion)]);


% Global Variables
clear global

global di_sensors
global sensor_id
global do_LEDs
global LEDs_id
global do_solenoids
global solenoid_id
global do_minute_marker
global mm_id
global zone_sum
global pos
global pos_opti
global pos_lin
global time_opti
global time_mat
global trig_on
global save_loc
global srate
global on_minutes                                                                                   
global hl
global hlcartx
global hlcartz
global hlcarto
global new_sensor_time
global last_Correct
global last_Sensor
global pumpOpen
global performance_vector
global perf_vec_idx
global trial_num
global performance_counter

% Save Location
[save_folder, filename, save_loc, ~, ~, waterlog_filepath] = CreateSavePaths(rat, exp);
disp(['Save Location: ' save_loc]);
fID = fopen(waterlog_filepath,'a');

% Set Timing and Alignment Parameters
run_time = 240*60;    % Seconds
srate = 20;           % Hz

% Position Parameters
% Construct pos vector to keep track of last 0.25 seconds
nquarter = ceil(srate/4);                      % #samples in a quarter second
pos = repmat([0 0 -500], nquarter, 1);         % Start pos with z-position way off
pos_opti = [nan, nan, nan];                    
pos_lin = [nan; nan];                                                                               
time_opti = [];                                                                                     
time_mat = [];                                                                                      
trig_on = [0; 0];                                                                                   
on_minutes = [false; false];                                                                        
zone_sum = 0;


%% NIDAQ Parameters
% NIDAQ Inputs
NIDAQ_sensor_chans = [51 17];
sensor_id = 1:length(NIDAQ_sensor_chans);

% NIDAQ Outputs
NIDAQ_solenoid_chans = [10 11];
solenoid_id = 1:length(NIDAQ_solenoid_chans);

NIDAQ_LEDs_chans = [1 2 3 37 38 5 39 6 40 41 42 43];
LEDs_id = 1:length(NIDAQ_LEDs_chans);

NIDAQ_mm_chans = [16];
mm_id = 1:length(NIDAQ_mm_chans);

% Create Input/Output Objects
% Warning if NIDAQ is not connected.
if ~debug_mode
    try
        warning('off','daq:Session:onDemandOnlyChannelsAdded');
        % Initiate NIDAQ digital inputs and outputs, and send success message to console.
        di_sensors = DigitalInput(NIDAQ_sensor_chans);
        disp('Successfully Initiated Digital Input: di_sensors.');

        do_solenoids = DigitalOutput(NIDAQ_solenoid_chans);
        disp('Successfully Initiated Digital Output: do_solenoids.');

        do_LEDs = DigitalOutput(NIDAQ_LEDs_chans);
        disp('Successfully Initiated Digital Output: do_LEDs.');

        do_minute_marker = DigitalOutput(NIDAQ_mm_chans);
        disp('Successfully Initiated Digital Output: do_minute_marker');
    catch
        % If no NIDAQ is detected, show warning message and set DI/DO objects to NaN.
        disp('Warning!');
        disp('Error connecting to NIDAQ- make sure that the board is connected to PCIe');
        disp('Running in debug mode');
        disp('NIDAQ object variables set to NaN.');
        debug_mode = true;
        di_sensors = nan;
        do_solenoids = nan;
        do_LEDs = nan;
    end
end


%% Water Delivery Parameters
% Solenoid Pump Open Duration
% Make sure lines are filled before starting script
% In Seconds, length of time water is delivered (small because of the gravity system)
    % Don't go lower than 0.02! solenoid won't work. sometimes unreliable up to 0.07 as well.
pumpOpen = 0.07;

% Prefill wells
do_solenoids.toggleNI(solenoid_id, pumpOpen);

% Initiate variables needed for water system
last_Sensor = 0;
last_Correct = 0;
performance_vector = [];
perf_vec_idx = 1;
new_sensor_time = [];
trial_num = 0;
performance_counter = 1;

%% Initialize Figure for LED Status, Rat Position, and Water Performance
% Set up window GUI for LED status and rat position update from motive.
% LED Status
hf = figure;
set(gcf,'Position', [810, 100, 1130, 590 ]);

% LED Status
ax = subplot(2,3,1);
imagesc(ax, 1);
colormap(ax,[1 0 0])
ht = text(ax, 1, 1, 'OFF', 'FontSize', 50, 'HorizontalAlignment', 'center');

% Linearized Position
subplot(2,3,2); 
hold on; 
title('Linear Position');
hl = plot(pos_lin);
hl(2) = plot(pos_lin,'r.');

% Water Performance
water_perf_fig = subplot(2,3,3);
hold on;
title('Water Performance');
xlabel('Minutes from start')
ylabel('Performance')

% X Position
subplot(2,3,4); 
hold on; 
title('X Cartesian Position');
hlcartx = plot(pos_opti(:,1));
hlcartx(2) = plot(pos_opti(:,1),'m*'); hlcartx(2).MarkerSize = 12;

% Z Position
subplot(2,3,5); 
hold on; 
title('Z Cartesian Position');
hlcartz = plot(pos_opti(:,3));
hlcartz(2) = plot(pos_opti(:,3), 'm*'); hlcartz(2).MarkerSize = 12;

% Overhead View
subplot(2,3,6); 
hold on; 
title('Overhead View');
hlcarto = plot(pos_opti(:,1), pos_opti(:,3));
hlcarto(2) = plot(pos_opti(end,1), pos_opti(end,3), 'm*');
hlcarto(2).MarkerSize = 12;


%% Motive Parameters
% Make sure track is aligned with z axis (long side of ground plane L) in optitrack calibration first!
% Connect to optitrack
trackobj = natnet;
trackobj.connect;

% Get track ends
% Starting position
input('Put rigid body at start of the track. Hit enter when done','s');
capture_pos(trackobj);
start_pos = pos(end,:);
disp(start_pos);
% start_pos = [-0.2557 0.1353 -3.6050];                                                             % For debugging only

% Ending position
input('Put rigid body at end of the track. Hit enter when done','s');
capture_pos(trackobj);
end_pos = pos(end,:);
disp(end_pos);
% end_pos = [-0.3754 0.2064 3.8861];                                                                % For debugging only

% Calculate angle of track for transformation to track coordinates
center = mean([start_pos; end_pos]);                                                                % Find track center
theta = atan2(end_pos(3)-start_pos(3), end_pos(1) - start_pos(1));                                  % Angle offset 
track_length = pdist2(end_pos, start_pos);                                                          % Calculate track length

% Calculate stimulation zone (takes stim zone and places it on the center of track)
ttl_zone = [-stim_proportion, stim_proportion]*track_length/2;                                      

% Code if track is aligned with Z-axis perfectly somehow
track_zdist = end_pos(3) - start_pos(3);                                                            % Set track distance along z-axis
ttl_zzone = [start_pos(3) + track_zdist/3, start_pos(3) + track_zdist*2/3];

% Display zone start and end on console
disp(['zone start = ' num2str(ttl_zone(1),'%0.2g')])
disp(['zone end = ' num2str(ttl_zone(2),'%0.2g')])

% Input for beginning of experiments
input('Ready to rock and roll. Hit enter when ready!','s');


%% Start Experiment
% Start timer to check at Sampling Rate(srate) Hz if rat is in the stim zone.
t_zone = timer('TimerFcn', @(x,y)zone_detect(trackobj, ax, ht, ttl_zone, theta, center), ...
    'StartFcn', @(x,y)send_start(), ...
    'StopFcn', @(x,y)send_end(), ...
    'Period', 1/srate, 'ExecutionMode', 'fixedRate');

t_minute = timer('TimerFcn', @(x,y)minute_marker(), 'Period', 60, 'ExecutionMode', 'fixedRate'); 

t_water = timer('TimerFcn',@(x,y)water_system(fID), 'Period', 1/srate, 'ExecutionMode', 'fixedRate');


% Cleanup Function
cleanup = onCleanup(@()myCleanupFun(rat, save_folder, hf, t_zone, t_minute, ax, ht));

% Start timer functions
start(t_zone);
start(t_minute);
start(t_water);

% Need these lines to end timers.
disp('Type "stop(t_zone); stop(t_minute); stop(t_water); dbcont" to finish and save');
keyboard

end % End function
%--------------------------------------------------------------------------------------------------%


%% Helper Functions -------------------------------------------------------------------------------%

%% Water Delivery System
% Check sensor at water ports and deliver water if correct port is triggered.
function [] = water_system(fID)
    global di_sensors
    global do_solenoids
    global sensor_id
    global solenoid_id
    global new_sensor_time
    global last_Correct
    global last_Sensor
    global pumpOpen 
    global performance_vector
    global perf_vec_idx
    global trial_num
    global performance_counter
    global firstport

    drawnow;
    % Read input from sensors
    port = di_sensors.readNI;
    activeport = find(port == 1);

    % Make sure activeport is not empty 
    if isempty(activeport)
        activeport = 0;
        return;
    end

    % Port 1 Triggered

    % First port in session
    % Identify if it is a repeat port
    if activeport == last_Sensor
        repeat = 1;
    else
        repeat = 0;
        new_sensor_time = datetime;
    end

    % Water trigger rules:
        % If correct, trigger solenoid on opposite side and swap the correct port to other side.
        % If incorrect, do nothing.
    if activeport == sensor_id(1) && last_Correct == 0
        do_solenoids.toggleNI(solenoid_id(2), pumpOpen);
        last_Correct = sensor_id(1);
        firstport = sensor_id(1);
        outcome = 1;

    % Triggered and correct
    elseif activeport == sensor_id(1) && last_Correct == sensor_id(2)
        do_solenoids.toggleNI(solenoid_id(2), pumpOpen);
        last_Correct = sensor_id(1);
        outcome = 1;

    % Triggered but wrong
    elseif activeport == sensor_id(1) && last_Correct ~= 0 && last_Correct ~= sensor_id(2)
        outcome = 0;

    % Port 2 Triggered
    % First port in session
    elseif activeport == sensor_id(2) && last_Correct == 0
        do_solenoids.toggleNI(solenoid_id(1), pumpOpen);
        last_Correct = sensor_id(2);
        firstport = sensor_id(2);
        outcome = 1;

    % Triggered and correct
    elseif activeport == sensor_id(2) && last_Correct == sensor_id(1)
        do_solenoids.toggleNI(solenoid_id(1), pumpOpen);
        last_Correct = sensor_id(2);
        outcome = 1;
    
    % Triggered but wrong
    elseif activeport == sensor_id(2) && last_Correct ~= 0 && last_Correct ~= sensor_id(1)
        outcome = 0;

    % Any other ports triggered (Shouldn't happen but just in case)
    elseif activeport ~= sensor_id(1) && activeport ~= sensor_id(2) && activeport ~=0
        outcome = 0;
    end

    % Update the what the last sensor activated was
    last_Sensor = activeport;

    % Calculate general performance
    d = datetime;

    % % If at least 15 seconds have passed since the rat initiated a new sensor visit
    if repeat == 0 || seconds(d - new_sensor_time) >= 15 
        if repeat == 1
            new_sensor_time = datetime;
        end

        performance_vector(perf_vec_idx) = outcome;

        if perf_vec_idx  < 10
            performance = sum(performance_vector)/length(performance_vector);
        else
            performance = sum(performance_vector(perf_vec_idx-9:perf_vec_idx))/10;
        end
        perf_vec_idx = perf_vec_idx + 1;
        disp(['Performance = ' num2str(performance)])

        performance_counter = performance_counter + 1;

        % Write to file.
        fprintf(fID,' %s %d %i \n', string(d,'dd-MMM-yyyy hh:mm:ss:SSS'), activeport, performance); %then write to file
        lastPrintTime = datetime; lastPrintTime.Format = 'hh:mm:ss:SSS';
        
        % Print number of trials
        if outcome == 1 
            trial_num = trial_num + 1;
            if rem(trial_num,2) == 0
                disp(['Trial ' num2str(trial_num/2) ' complete'])
            end
        end
    end

end


%% Minute Marker
% Turns on for even minutes and off for odd minutes
function [] = minute_marker()

global do_minute_marker
global mm_id

disp('Minute Marker!');
try 
    do_minute_marker.toggleNI(mm_id, 0.001)
catch ME
    if ~strcmpi(ME.identifier, 'MATLAB:UndefinedFunction')
        rethrow(ME)
    end
end
end

%% Start Recording Marker
function [] = send_start()

global do_minute_marker
global mm_id

disp('Start!')
try 
    do_minute_marker.toggleNI(mm_id, 0.003)
catch ME
    if ~strcmpi(ME.identifier, 'MATLAB:UndefinedFunction')
        rethrow(ME)
    end
end
end

%% End Recording Marker
function [] = send_end()
global time_opti
global time_mat
global pos_lin
global pos_opti
global trig_on
global on_minutes
global save_loc
global do_minute_marker
global mm_id

% Save variables at end time
save(save_loc, 'time_opti', 'time_mat', 'pos_lin', 'pos_opti', 'trig_on', ...
'on_minutes');

disp('End!')
try 
    do_minute_marker.toggleNI(mm_id, 0.003)
catch ME
    if ~strcmpi(ME.identifier, 'MATLAB:UndefinedFunction')
        rethrow(ME)
    end
end


end


%% Capture Live Position
function [delta_pos] = capture_pos(c)

% adjust this to get delta pos from 0.25 sec prior!!!
global pos
global pos_opti
global time_opti
global time_mat

frame = c.getFrame; % get frame
time_opti = [time_opti; frame.Timestamp];
time_mat = [time_mat; clock];

% Add position to bottom of position tally
pos = [pos; ...
    frame.RigidBody(1).x, frame.RigidBody(1).y, frame.RigidBody(1).z];
pos_opti = [pos_opti; ...
    frame.RigidBody(1).x, frame.RigidBody(1).y, frame.RigidBody(1).z];

% get change in position from  0.25 seconds ago
delta_pos = pos(end,:) - pos(1,:);

% update pos to chop off most distant time point
pos = pos(2:end,:);

end


%% Detect if in TTL Zone and Trigger
function [] = zone_detect(c, ax, ht, ttl_zone, theta, center)

global pos
global pos_opti
global time_opti
global time_mat
global pos_lin
global trig_on
global save_loc
global zone_sum
global srate
global D4value
global on_minutes

delta_pos = capture_pos(c); % get position
pos_curr = pos(end,:);
pos_s = cart_to_track(pos_curr, theta, center);
pos_lin = [pos_lin; pos_s];

% Turn TTL off if rat's position has not changed at all (most likely
% optitrack can't find it) OR if rat is chilling within zone for greater
% than zone_thresh seconds
zone_thresh = 15;
if all(delta_pos == 0) || zone_sum >= zone_thresh*srate %sqrt(sum(delta_pos.^2)) < 0.05 %
    trigger_off(ax, ht, pos_s)
    trig_on = [trig_on; 0];
    if (pos_s <= ttl_zone(1)) || (pos_s >= ttl_zone(2))
        zone_sum = 0; % reset time in trigger zone to 0
    end
else % Logic to trigger is the rat is in the appropriate zone below
    if (pos_s > ttl_zone(1)) && (pos_s < ttl_zone(2)) %pos_curr(3) > ttl_zone(1) && pos_curr(3) < ttl_zone(2)
        trigger_on(ax, ht, pos_s)
        trig_on = [trig_on; 1];
        zone_sum = zone_sum + 1; % Increment time tracked in trigger zone
        
    % Send D2 to 0V if outside of zone and currently at 5V
    elseif (pos_s <= ttl_zone(1)) || (pos_s >= ttl_zone(2)) %(pos_curr(3) <= ttl_zone(1)) || (pos_curr(3) >= ttl_zone(2))
        trigger_off(ax, ht, pos_s)
        trig_on = [trig_on; 0];
        zone_sum = 0; % reset time in trigger zone to 0
    end
end

on_minutes = [on_minutes; D4value];

save(save_loc, 'time_opti', 'time_mat', 'pos_lin', 'pos_opti', 'trig_on', ...
    'on_minutes');
end


%% Turn on LED/Screen
function [] = trigger_on(ax, ht, pos_curr)

global do_LEDs
global LEDs_id
global pos_lin
global pos_opti
global trig_on
global hl
global hlcartx
global hlcartz
global hlcarto

if length(pos_curr) == 3
    pos_use = pos_curr(3);
else
    pos_use = pos_curr;
end

if isobject(do_LEDs)
    % Need code for having signal in initial off state
    do_LEDs.Signal_Off_NI(LEDs_id);
    do_LEDs.toggleNI(LEDs_id, 0.01);
end

% What does this do
text_append = ['-' num2str(pos_use, '%0.2g')];

% Update window for LED ON.
colormap(ax,[0 1 0])
ht.String = ['ON' text_append];
hl(1).YData = pos_lin;
hl(2).XData = find(trig_on == 1);
hl(2).YData = pos_lin(trig_on == 1);

nframes = size(pos_opti,1);
hlcartx(1).YData = pos_opti(:,1);
hlcartx(2).XData = nframes;
hlcartx(2).YData = pos_opti(end,1);

hlcartz(1).YData = pos_opti(:,3);
hlcartz(2).XData = nframes;
hlcartz(2).YData = pos_opti(end,3);

hlcarto(1).XData = pos_opti(:,1);
hlcarto(1).YData = pos_opti(:,3);
hlcarto(2).XData = pos_opti(end,1);
hlcarto(2).YData = pos_opti(end,3);

end


%% Turn off LED/Screen
function [] = trigger_off(ax, ht, pos_curr)

global do_LEDs
global hl
global hlcartx
global hlcartz
global hlcarto
global pos_lin
global pos_opti
global trig_on

if length(pos_curr) == 3
    pos_use = pos_curr(3);
else
    pos_use = pos_curr;
end

if isobject(do_LEDs)
    % Need code for having signal in initial off state

    % Testing stuff out
    do_LEDs.Signal_Off_NI([1 2 3 4 5 6 7 8 9 10 11 12])
end

text_append = ['-' num2str(pos_use, '%0.2g')];

% Update window for LED OFF.
colormap(ax,[1 0 0])
ht.String = ['OFF' text_append];
hl(1).YData = pos_lin;
hl(2).XData = find(trig_on == 1);
hl(2).YData = pos_lin(trig_on == 1);

nframes = size(pos_opti,1);
hlcartx(1).YData = pos_opti(:,1);
hlcartx(2).XData = nframes;
hlcartx(2).YData = pos_opti(end,1);

hlcartz(1).YData = pos_opti(:,3);
hlcartz(2).XData = nframes;
hlcartz(2).YData = pos_opti(end,3);

hlcarto(1).XData = pos_opti(:,1);
hlcarto(1).YData = pos_opti(:,3);
hlcarto(2).XData = pos_opti(end,1);
hlcarto(2).YData = pos_opti(end,3);

end


%% Convert cartesian position to track length
function [s] = cart_to_track(pos_curr, theta, center)
% S = position on track
x = pos_curr(1);
y = pos_curr(2);
z = pos_curr(3);
xmid = center(1);
ymid = center(2);
zmid = center(3);

% Calculate s two different ways
s1 = (z - zmid)/sin(theta);
s2 = (x - xmid)/cos(theta);

% Make sure we aren't dividing by zero for calculations
cos_lims = [-pi(), -3*pi()/4; -pi()/4, pi()/4; 3*pi()/4, pi()];
sin_lims = [-3*pi()/4 -pi()/4; pi()/4 3*pi()/4];

% Use the calculation that doesn't have a divide by zero.
if any(cos_lims(:,1) <= theta & theta < cos_lims(:,2))
    s = s2;
elseif any(sin_lims(:,1) <= theta & theta < sin_lims(:,2))
    s = s1;
end

end


%% Cleanup function to save everything and close files when exiting
% Clear variables when function is stopped
function myCleanupFun(rat, save_folder, h, t_zone, t_minute, ax, ht)
    disp('Running Cleanup Function');
    d = datetime;

    % Save figure
    saveas(h, fullfile(save_folder, [rat, '_', char(d,'dd-MMM-yyyy_hh.mm.ss.SSS') '_performance.fig']));
    
    % Cleanup timers and position variables
    trigger_off(ax, ht, nan);
    send_end();
    
    stop(t_zone);
    stop(t_minute);
    
    close(ax.Parent(1));
    
    stop(timerfind);
    delete(timerfind);
end