clc; clearvars;
% You may run just once.
% run('VLFEATROOT/toolbox/vl_setup');

model_data_path = [get_dataset_path() '0-24(1)\0-24\anchiceratops\'];
% model_data_path = [get_dataset_path() '0-24(1)\0-24\ankylosaurus_brown\'];

% model_f_name = 'data/model_anchiceratops_multi';
model_f_name = 'data/model_anchiceratops_single';
% model_f_name = 'data/model_ankylosaurus_brown_multi';

%% Read model
% model_path = [get_dataset_path() '0-24(1)\0-24\anchiceratops\'];
model_fname = [model_data_path 'model.nvm'];
model = read_model(model_fname);
save (model_f_name, 'model');

%% Offline model preparation
% model = model.calc_multiscale_descriptors(model_data_path);
model = model.calc_descriptor(model_data_path);
save (model_f_name, 'model');
