function [] = Save_PCD_Settings(save_folder, rat, exp, stim_proportion, run_time, srate, NIDAQ_sensor_chans, NIDAQ_solenoid_chans, NIDAQ_LEDs_chans, NIDAQ_mm_chans, pumpOpen)
starttime = datetime;
date = num2str(yyyymmdd(starttime));
fullfile = strcat(save_folder, '\', rat, '_', exp, '_Settings_', date, '.txt');

settings_fid = fopen(fullfile, 'wt');

if settings_fid ~= -1
    fprintf(settings_fid, 'Save Location: %s\n', fullfile);
    fprintf(settings_fid, 'Rat: %s\n', rat);
    fprintf(settings_fid, 'Experiment: %s\n', exp);
    fprintf(settings_fid, 'Stim Proportion: %f\n', stim_proportion);
    fprintf(settings_fid, 'Max Run Time: %is\n', run_time);
    fprintf(settings_fid, 'Sampling Rate: %dHz \n', srate);
    fprintf(settings_fid, '%s \n', ['NIDAQ Sensor Channels: ', num2str(NIDAQ_sensor_chans)]);
    fprintf(settings_fid, '%s \n', ['NIDAQ Solenoid Channels: ', num2str(NIDAQ_solenoid_chans)]);
    fprintf(settings_fid, '%s \n', ['NIDAQ LED Channels: ', num2str(NIDAQ_LEDs_chans)]);
    fprintf(settings_fid, '%s \n', ['NIDAQ Minute Marker Channels: ', num2str(NIDAQ_mm_chans)]);
    fprintf(settings_fid, 'Solenoid Opening Time(s): %fs\n', pumpOpen);
    fclose(settings_fid);
else
    warningMessage = sprintf('Cannot open file %s', fullfile);
    uiwait(warndlg(warningMessage));
end