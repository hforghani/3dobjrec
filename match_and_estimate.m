clearvars; close all; clc;

addpath model daisy utils EPnP PairwiseMatching;

% You may run just once.
% run('VLFEATROOT/toolbox/vl_setup');

%% Initialize.
% Set these parameters:
case_name = 'all25';
query_im_name = 'test_img/test5.jpg';

parts = textscan(query_im_name, '%s', 'delimiter', '/');
parts = textscan(parts{1}{end}, '%s', 'delimiter', '.');
exact_name = parts{1}{1};
matches_f_name = ['data/matches/' case_name '_' exact_name];

desc_model_f_name = ['data/model_desc/' case_name];
desc_model = load(desc_model_f_name);

ply_fname = ['result/res_' exact_name '.ply'];
res_fname = ['result/res_' exact_name '.txt'];

%% Load models.
fprintf('loading models ... ');
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
[query_frames, correspondences, points, corr_dist] = match_2d_to_3d(image, desc_model);
save(matches_f_name, 'query_frames', 'points', 'correspondences', 'corr_dist');
toc;

%% Filter correspondences.
fprintf('filtering correspondences ...\n');
tic;
[sel_model_i, sel_corr, sel_adj_mat] = ...
    filter_corr(query_frames, points, correspondences, corr_dist, models, desc_model.obj_names, query_im_name);
% [sel_model_i, sel_corr, sel_adj_mat] = ...
%     match_corr_graph(query_frames, points, correspondences, corr_dist, models, desc_model.obj_names, query_im_name);
toc;
fprintf('done\n');

%% Estimate pose.
tic;
query_poses = query_frames(1:2,:);
[transforms, rec_indexes] = estimate_multi_pose(query_poses, points, sel_model_i, sel_corr, sel_adj_mat, models, desc_model.obj_names, query_im_name);
toc;

%% Save results as ply and txt.
create_ply(transforms, rec_indexes, desc_model.obj_names, ply_fname);

fid = fopen(res_fname, 'w');
fprintf(fid, 'recognized objects:\n\n');
for i = 1:length(rec_indexes)
    fprintf(fid, '%s\n', desc_model.obj_names{rec_indexes(i)});
end
fclose(fid);
