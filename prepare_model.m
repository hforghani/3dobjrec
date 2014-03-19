clc; clearvars;
tic;

% You may run just once.
% run('VLFEATROOT/toolbox/vl_setup');

model_data_path = [get_dataset_path() '0-24(1)\0-24\anchiceratops\'];
% model_data_path = [get_dataset_path() '0-24(1)\0-24\ankylosaurus_brown\'];

% prepared_model_fname = 'data/model_anchiceratops_multi';
prepared_model_fname = 'data/model_anchi_multi_kd';
% prepared_model_fname = 'data/model_anchiceratops_single';
% prepared_model_fname = 'data/model_ankylosaurus_brown_multi';
% prepared_model_fname = 'data/model_ankylosaurus_brown_single';

%% Read model
model_fname = [model_data_path 'model.nvm'];
model = read_model(model_fname);
save (prepared_model_fname, 'model');

%% Offline model preparation
model = model.calc_multi_desc(model_data_path);
% scale = 1.2;
% model = model.calc_single_desc(scale, model_data_path);
save (prepared_model_fname, 'model');

toc;
