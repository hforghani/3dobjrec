clearvars; close all; clc;
% You may run just once.
% run('VLFEATROOT/toolbox/vl_setup');

model_f_name = 'data/model_anchi_multi_kd';
% model_f_name = 'data/model_anchiceratops_multi';
% model_f_name = 'data/model_anchiceratops_single';
% model_f_name = 'data/model_ankylosaurus_brown_multi';
% model_f_name = 'data/model_ankylosaurus_brown_single';

matches_f_name = 'data/matches_anchi_test0_t100_kd';
% matches_f_name = 'data/matches_anchi_test1_thresh100';
% matches_f_name = 'data/matches_anchiceratops_dense';
% matches_f_name = 'data/matches_anky_test1_t100';
% matches_f_name = 'data/matches_anky_test1_single';

test_im_name = [get_dataset_path() '0-24(1)\0-24\anchiceratops\db_img\1090.jpg'];
% test_im_name = 'test/test1.jpg';
% test_im_name = 'test/test2.jpg';

model_file = load(model_f_name);
model = model_file.model;
image = imread(test_im_name);

%% Match 2d-to-3d
edge_thresh = 100;
[matches2d, matches3d, matches_dist] = match_2d_to_3d(image, model, matches_f_name, edge_thresh);
% scale = 1.2;
% [matches2d, matches3d, matches_dist] = match_2d_to_3d_single(image, model, matches_f_name, scale);

save(matches_f_name, 'matches2d', 'matches3d', 'matches_dist');

figure;
imshow(image);
hold on;
scatter(matches2d(1,:), matches2d(2,:), 'r', 'filled');
