clc; clearvars; close all;
% You may run just once.
% run('VLFEATROOT/toolbox/vl_setup');

% load model;
load model_multiscale;

% model_path = [get_dataset_path() '0-24(1)\0-24\anchiceratops\'];
% colored = imread([model_path 'db_img\1090.jpg']);
path = 'test.jpg';
image = imread(path);

%% Match 2d-to-3d
[matches2d, matches3d] = match_2d_to_3d(image, model);
save('matches.mat', 'matches2d', 'matches3d');

figure;
imshow(image);
hold on;
scatter(matches2d(1,:), matches2d(2,:), 'r', 'filled');