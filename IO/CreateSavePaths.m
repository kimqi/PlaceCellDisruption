function [project_folder, project_filename, project_filepath, waterlog_folder, waterlog_filename, waterlog_filepath] = CreateSavePaths(rat,exp)
%% Create Save Paths and set save locations for current script.

% Initialize parameters
starttime = datetime;

% Prompt user for save location of project
project_folder = [uigetdir('E:\Brian\','Select Project Root Folder- Default is Brian') '\'  'Behavior\' rat];

if ~exist(project_folder, 'dir')
    mkdir(project_folder)
end

% Matfile Save Location
project_filename = [rat '_' exp '_' num2str(yyyymmdd(starttime)) '.mat'];
project_filepath = fullfile(project_folder, project_filename);
file_num = 1;

while exist(project_filepath, 'dir')
    project_filename = [rat '_' num2str(yyyymmdd(datetime)) '_' num2str(file_num) '.mat'];
    file_num = file_num + 1;
    project_filepath = fullfile(project_folder, project_filename);
end
disp(['Matfile Save Location: ' project_filepath]);

% Water Performance Log Save File Location
waterlog_folder = fullfile(project_folder, 'WaterPerformance');

if ~exist(waterlog_folder, 'dir')
    mkdir(waterlog_folder)
end

waterlog_filename = [rat '_' num2str(yyyymmdd(starttime)) '.txt'];
waterlog_filepath = fullfile(project_folder, 'WaterPerformance', waterlog_filename);
file_num = 1;

while exist(waterlog_filepath, 'file')
    waterlog_filename = [rat '_' num2str(yyyymmdd(datetime)) '_' num2str(file_num) '.txt'];
    file_num = file_num + 1;
    waterlog_filepath = fullfile(waterlog_folder, waterlog_filename);
end
disp(['Water Performance Log Save Location: ' waterlog_filepath]);

