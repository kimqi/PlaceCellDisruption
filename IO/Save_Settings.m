function [] = Save_Settings(folder, rat, exp, track, NIDAQ_sensor_chans, NIDAQ_solenoid_chans, pumpOpen)
date = num2str(yyyymmdd(datetime));
full_filepath = strcat(folder, '\', rat, '_', exp, '_Settings_', date, '.txt');
settings_fid = fopen(full_filepath, 'wt');

if settings_fid ~= -1
    % Rat Settings
    fprintf(settings_fid, 'Save Location: %s\n', full_filepath);
    fprintf(settings_fid, 'Rat: %s\n', rat);
    fprintf(settings_fid, 'Experiment: %s\n', exp);
    fprintf(settings_fid, 'Track: %s\n', track);

    % NIDAQ Settings
    fprintf(settings_fid, '%s \n', ['NIDAQ Sensor Channels: ', num2str(NIDAQ_sensor_chans)]);
    fprintf(settings_fid, '%s \n', ['NIDAQ Solenoid Channels: ', num2str(NIDAQ_solenoid_chans)]);
    fprintf(settings_fid, 'Solenoid Opening Time(s): %fs\n', pumpOpen);
    fclose(settings_fid);
else
    warningMessage = sprintf('Cannot open file %s', fullfile);
    uiwait(warndlg(warningMessage));  
end

end

