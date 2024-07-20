function vargout = Define_Track(track, trackobj, pos)
turns = 0;
if track == 'Sarthe'
    turns = 1;
end

nOutputs = 2 + turns;
vargout = cell(1,nOutputs);

% Get Track Start and End Positions
input('Put rigid body at start of the track. Hit enter when done','s');
capture_pos(trackobj);
start_pos = pos(end,:);
vargout{1} = start_pos;
disp(start_pos);

input('Put rigid body at end of the track. Hit enter when done','s');
capture_pos(trackobj);
end_pos = pos(end,:);
vargout{2} = end_pos;
disp(end_pos);

% Get inputs for corners
for ii = 1:turns
    input('Put rigid body on a corner of the track. Hit enter when done','s');
    capture_pos(trackobj);
    turn_pos = pos(end,:);
    vargout{2+ii} = turn_pos;
    disp(turn_pos);
end

end

