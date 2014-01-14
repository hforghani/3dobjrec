clc; close all;
% You may run just once.
% run('VLFEATROOT/toolbox/vl_setup');

model_path = 'E:\datasets\Microsoeft_research\0-24(1)\0-24\anchiceratops\';
colored = imread([model_path 'db_img\1090.jpg']);

%% Read model
model_fname = [model_path 'model.nvm'];
model = read_model(model_fname);
save model;

%% Offline model preparation
model = prepare_model(model, model_path);
save model;

%% Match 2d-to-3d
matches = match_2d_to_3d(colored, model);
