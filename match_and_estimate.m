clearvars; close all; clc;

% You may run just once.
% run('VLFEATROOT/toolbox/vl_setup');

% obj_name = 'anchiceratops';
obj_name = 'axe_knight';

model_f_name = ['data/model_' obj_name];
desc_model_f_name = ['data/model_desc_' obj_name];

% query_im_name = [get_dataset_path() '0-24(1)/0-24/anchiceratops/db_img/1090.jpg'];
% query_im_name = [get_dataset_path() '0-24(1)/0-24/axe_knight/db_img/1090.jpg'];
 query_im_name = 'test/test3.jpg';

parts = textscan(query_im_name, '%s', 'delimiter', '/');
parts = textscan(parts{1}{end}, '%s', 'delimiter', '.');
exact_name = parts{1}{1};
matches_f_name = ['data/matches_' obj_name '_' exact_name];

%% Match 2d to 3d
load(model_f_name);
points = model.points;
clear model;
desc_model = load(desc_model_f_name);

image = imread(query_im_name);
[matches2d, matches3d, matches_dist] = match_2d_to_3d(image, desc_model, points, matches_f_name);
save(matches_f_name, 'matches2d', 'matches3d', 'matches_dist');

%% Estimate pose.
[rotation_mat, translation_mat] = estimate_pose(matches_f_name, model_f_name, query_im_name);
