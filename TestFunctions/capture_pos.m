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
