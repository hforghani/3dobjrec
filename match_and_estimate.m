clearvars; close all; clc;
addpath model;
addpath daisy;

% You may run just once.
% run('VLFEATROOT/toolbox/vl_setup');

case_name = 'all15';

desc_model_f_name = ['data/model_desc/' case_name];

% query_im_name = [get_dataset_path() '0-24(1)/0-24/anchiceratops/db_img/1093.jpg'];
% query_im_name = [get_dataset_path() '0-24(1)/0-24/axe_knight/db_img/1090.jpg'];
% query_im_name = [get_dataset_path() '0-24(1)/0-24/airborne_soldier/db_img/1114.jpg'];
query_im_name = 'test/test5.jpg';

parts = textscan(query_im_name, '%s', 'delimiter', '/');
parts = textscan(parts{1}{end}, '%s', 'delimiter', '.');
exact_name = parts{1}{1};
matches_f_name = ['data/matches/' case_name '_' exact_name];

%% Match 2d to 3d
tic; 

desc_model = load(desc_model_f_name);

obj_count = length(desc_model.obj_names);
points_array = cell(obj_count, 1);
for i = 1:obj_count
    model_f_name = ['data/model/' desc_model.obj_names{i}];
    load(model_f_name);
    points_array{i} = model.points;
end

image = imread(query_im_name);
[query_poses, correspondences, points] = match_2d_to_3d(image, desc_model);
save(matches_f_name, 'query_poses', 'points', 'correspondences');
toc;

%% Filter correspondences.
fprintf('filtering correspondences ...\n');
tic;
correspondences = ...
    filter_corr(query_poses, points, correspondences, desc_model, points_array, query_im_name);
toc;
fprintf('done\n');

%% Estimate pose.
toc;
transforms = estimate_multi_pose(query_poses, points, match_model_indexes, ...
    desc_model.obj_names, query_im_name);
toc;
