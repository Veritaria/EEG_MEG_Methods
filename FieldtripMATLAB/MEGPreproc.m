clear; close all; clc;

[ret, hostname] = system('hostname');
if ret ~= 0
    hostnme = getenv('HOSTNAME');
end
hostname = strtrim(hostname);

if contains(hostname, 'hpc')
    % You are running your code on HPC
    curr_dir = pwd;
    path_parts = strsplit(curr_dir, filesep);
    fieldtrip_path = fullfile(filesep, path_parts{1:end-1}, 'fieldtrip');
    dataPath = fullfile(filesep, 'scratch', 'work', 'courses', ...
                    'PSYCH-GA-3405-2024fa');
else
    % Define the paths and initialize Fieldtrip
    my_user_id = 'mdd9787'; % change this to your netID
    curr_dir = pwd;
    path_parts = strsplit(curr_dir, filesep);
    base_dir = fullfile(filesep, path_parts{1:3});
    fieldtrip_path = fullfile(base_dir, 'Documents', 'MATLAB', 'fieldtrip-20220104');
    dataPath = fullfile(base_dir, 'Library', 'CloudStorage', ...
        strcat('GoogleDrive-', my_user_id, '@nyu.edu'), ...
        'My Drive', 'Coursework', 'EEG MEG methods', 'ClassData');
end
meg_path = fullfile(dataPath, 'MEG');
eeg_path = fullfile(dataPath, 'EEG');

% Add fieldtrip to path
addpath(fullfile(fieldtrip_path));
ft_defaults;
%% Load data
groupName = 'GroupB';
recRoot = fullfile(meg_path, groupName, 'Recording');

lstFiles = dir(recRoot);
lstFiles = {lstFiles.name};

% Filter the files based on their extensions
sqdFiles = lstFiles(endsWith(lstFiles, '_NR.sqd'));
mrkFiles = lstFiles(endsWith(lstFiles, '.mrk'));
elpFiles = lstFiles(endsWith(lstFiles, 'Points.txt'));
hsFiles = lstFiles(endsWith(lstFiles, 'HS.txt'));
matFiles = lstFiles(endsWith(lstFiles, '.mat'));

% In this case, second file is the one we want to load
% this will vary depending on which group's data you are analyzing and how
% many files you have.
ff = sqdFiles{2};
rec_filepath = fullfile(recRoot, ff);

% % Place holder to load marker, fiducials and headshape files
% mrk = cellfun(@(x) fullfile(recRoot, x), mrkFiles, 'UniformOutput', false);
% elp = fullfile(recRoot, elpFiles{1});
% hsp = fullfile(recRoot, hsFiles{1});

%%
hdr = ft_read_header(rec_filepath);
% Load the raw data using FieldTrip
cfg = [];
cfg.datafile = rec_filepath;
all_rawData = ft_preprocessing(cfg);
% Alternatively load the existing all_rawData in mat format to make it
% faster
% all_rawData = load(fullfile(recRoot, matFiles{1}));
% all_rawData = all_rawData.all_rawData;


%% split the recording channels in data and trigger channels
cfg = [];
cfg.channel = all_rawData.grad.label;
raw_meg_data = ft_selectdata(cfg, all_rawData);

cfg = [];
cfg.channel = all_rawData.label(...
    ~ismember(all_rawData.label, all_rawData.grad.label));
raw_trig_data = ft_selectdata(cfg, all_rawData);

% save(fullfile(recRoot, 'all_rawData.mat'), 'all_rawData', '-v7.3');


%% plot sensors 
% ft_plot_sens()
%% generously cut the data
% words: 2.5s pre to 5s post (they will overlap)
% story: 5s pre to 5s post

%% Create a layout based on grad positions
grad = ft_read_sens(rec_filepath);
cfg = [];
cfg.grad = grad;
lay = ft_prepare_layout(cfg);

%% Visualize data and screen for artifacts
cfg = [];
cfg.viewmode = 'vertical';
cfg.ylim = [-1e-13, 1e-13];
cfg.layout = lay;
cfg.preproc.hpfilter = 'yes';
cfg.preproc.hpfreq = 0.5;
cfg.preproc.hpfiltord = 4;

%% first step mark ALL artifacts
cfg_out_allArt = ft_databrowser(cfg, raw_meg_data);

%% second step remove artifacts that could be eye related
cfg_out_noEye = ft_databrowser(cfg_out_allArt, raw_meg_data);


%% Define triggers
cfg 
event = ft_read_event(rec_filepath, 'chanidx':)

cfg = [];
cfg.dataset = rec_filepath;
cfg.trialdef.eventtype = '?';
dummy = ft_definetrial(cfg)
