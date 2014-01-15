clc; close all;
% You may run just once.
% run('VLFEATROOT/toolbox/vl_setup');

load model;

model_path = [get_dataset_path() '0-24(1)\0-24\anchiceratops\'];
colored = imread([model_path 'db_img\1090.jpg']);

%% Match 2d-to-3d
matches = match_2d_to_3d(colored, model);
