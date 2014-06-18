clearvars; close all; clc;
addpath model;
addpath daisy;

% You may run just once.
% run('VLFEATROOT/toolbox/vl_setup');

% Set these parameters:
case_name = 'all10';
query_im_name = 'test_img/test5.jpg';
ply_fname = 'result/test5.ply';

parts = textscan(query_im_name, '%s', 'delimiter', '/');
parts = textscan(parts{1}{end}, '%s', 'delimiter', '.');
exact_name = parts{1}{1};
matches_f_name = ['data/matches/' case_name '_' exact_name];

fprintf('loading model ... ');
desc_model_f_name = ['data/model_desc/' case_name];
desc_model = load(desc_model_f_name);
obj_count = length(desc_model.obj_names);
models = cell(obj_count, 1);
for i = 1:obj_count
    model_f_name = ['data/model/' desc_model.obj_names{i}];
    load(model_f_name);
    models{i} = model;
end
fprintf('done\n');

%% Match 2d to 3d
tic;
image = imread(query_im_name);
[query_frames, correspondences, points] = match_2d_to_3d(image, desc_model);
save(matches_f_name, 'query_frames', 'points', 'correspondences');
toc;

%% Filter correspondences.
fprintf('filtering correspondences ...\n');
tic;
correspondences = ...
    filter_corr(query_frames, points, correspondences, models, desc_model.obj_names, query_im_name);
toc;
fprintf('done\n');

%% Estimate pose.
tic;
query_poses = query_frames(1:2,:);
[transforms, rec_indexes] = estimate_multi_pose(query_poses, points, correspondences, models, desc_model.obj_names, query_im_name);
toc;

%% Create ply output.
create_ply(transforms, rec_indexes, desc_model.obj_names, ply_fname);
