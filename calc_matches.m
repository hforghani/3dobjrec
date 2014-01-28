clearvars; close all; clc;
% You may run just once.
% run('VLFEATROOT/toolbox/vl_setup');

model_f_name = 'data/model_anchiceratops_multi.mat';
% model_f_name = 'data/model_ankylosaurus_brown_multi.mat';

% matches_f_name = 'data/matches_anchiceratops.mat';
% matches_f_name = 'data/matches_ankylosaurus_brown.mat';
matches_f_name = 'data/matches_ankylosaurus_brown_dense.mat';

% test_im_name = [get_dataset_path() '0-24(1)\0-24\anchiceratops\db_img\1090.jpg'];
test_im_name = 'test.jpg';

load(model_f_name);
image = imread(test_im_name);

%% Match 2d-to-3d
[matches2d, matches3d, matches_dist] = match_2d_to_3d(image, model, matches_f_name);
save(matches_f_name, 'matches2d', 'matches3d', 'matches_dist');

figure;
imshow(image);
hold on;
scatter(matches2d(1,:), matches2d(2,:), 'r', 'filled');
