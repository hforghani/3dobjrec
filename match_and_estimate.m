clearvars; close all; clc;
addpath model;
addpath daisy;

% You may run just once.
% run('VLFEATROOT/toolbox/vl_setup');

% obj_name = 'anchiceratops';
obj_name = 'all';
obj_names = {'anchiceratops', 'axe_knight'};

% model_f_name = ['data/model_' obj_name];
desc_model_f_name = ['data/model_desc_' obj_name];

% query_im_name = [get_dataset_path() '0-24(1)/0-24/anchiceratops/db_img/1093.jpg'];
% query_im_name = [get_dataset_path() '0-24(1)/0-24/axe_knight/db_img/1090.jpg'];
 query_im_name = 'test/test5.jpg';

parts = textscan(query_im_name, '%s', 'delimiter', '/');
parts = textscan(parts{1}{end}, '%s', 'delimiter', '.');
exact_name = parts{1}{1};
matches_f_name = ['data/matches_' obj_name '_' exact_name];

%% Match 2d to 3d
obj_count = length(obj_names);
points_array = cell(obj_count, 1);
for i = 1:obj_count
    model_f_name = ['data/model_' obj_names{i}];
    load(model_f_name);
    points_array{i} = model.points;
    clear model;
end
desc_model = load(desc_model_f_name);

image = imread(query_im_name);
[matches2d, matches3d, match_model_indexes, match_point_indexes, matches_dist] = match_2d_to_3d(image, desc_model, points_array);
save(matches_f_name, 'matches2d', 'matches3d', 'match_model_indexes', 'match_point_indexes', 'matches_dist');

%% Filter correspondences.
indexes = filter_corr(matches2d, matches3d, match_model_indexes, match_point_indexes);
matches2d = matches2d(:, indexes);
matches3d = matches3d(:, indexes);
match_model_indexes = match_model_indexes(:, indexes);
match_point_indexes = match_point_indexes(:, indexes);
matches_dist = matches_dist(:, indexes);

%% Estimate pose.
transforms = estimate_multi_pose(matches2d, matches3d, match_model_indexes, obj_names, query_im_name);

