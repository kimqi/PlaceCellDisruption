function [folder, filename, filepath, water_folder, water_filename, water_path] = CreateSavePaths(rat, exp, format,track_perf)
%% Create Save Paths and set save locations for current script.

% Initialize parameters
starttime = datetime;
water_folder = '';
water_filename = '';
water_path = '';

% Prompt user for save location of project
base_folder = [uigetdir('E:\Brian\Behavior','Select Animal Data Folder')];
folder = [base_folder '\' exp];

if ~exist(folder, 'dir')
    mkdir(folder)
end

% Save file name
filename = [rat '_' exp '_' num2str(yyyymmdd(starttime)) format];
filepath = fullfile(folder, filename);
file_num = 1;
water_num = 1;

while exist(filepath,'file')
    filename = [rat '_' num2str(yyyymmdd(datetime)) '_' num2str(file_num) format];
    filepath = fullfile(folder, filename);
    file_num = file_num + 1;
end

if track_perf == true
    water_folder = strcat([folder '\Water-Performance']);
    if ~exist(water_folder, 'dir')
        mkdir(water_folder)
    end
    water_filename = [rat '_' exp '_Water-Performance_' num2str(yyyymmdd(starttime)) format];
    water_path = fullfile(water_folder, water_filename);

    while exist(water_path, 'file')
        water_filename = [rat '_' exp '_Water-Performance_' num2str(yyyymmdd(starttime)) '_' num2str(water_num) format];
        water_path = fullfile(water_folder, water_filename);
        water_num = water_num + 1;
    end
end

