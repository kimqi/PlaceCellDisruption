function [] = minute_marker_test(do_minute_marker, mm_id)
disp('Minute Marker!');
try 
    do_minute_marker.toggleNI(mm_id, 0.0001)
catch ME
    if ~strcmpi(ME.identifier, 'MATLAB:UndefinedFunction')
        rethrow(ME)
    end
end
end

 
