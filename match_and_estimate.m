clearvars; close all;

model_f_name = 'data/model_anchi_daisy_kd';
% model_f_name = 'data/model_anchi_multi_kd';
% model_f_name = 'data/model_anchiceratops_multi';
% model_f_name = 'data/model_anchiceratops_single';
% model_f_name = 'data/model_ankylosaurus_brown_multi';
% model_f_name = 'data/model_ankylosaurus_brown_single';

% query_im_name = [get_dataset_path() '0-24(1)\0-24\anchiceratops\db_img\1090.jpg'];
query_im_name = 'test/test1.jpg';
% query_im_name = 'test/test2.jpg';

% matches_f_name = 'data/matches_anchi_test0_daisy_kd';
matches_f_name = 'data/matches_anchi_test2_onekd';
% matches_f_name = 'data/matches_anchi_test1_thresh100';
% matches_f_name = 'data/matches_anchiceratops_dense';
% matches_f_name = 'data/matches_anky_test1_t100';
% matches_f_name = 'data/matches_anky_test1_single';

result_f_name = 'data/result_anchi_daisy_kd';
% result_f_name = 'data/result_anchiceratops_dense';

%% Match 2d-to-3d
load(model_f_name);
image = imread(query_im_name);
[matches2d, matches3d, matches_dist] = match_2d_to_3d(image, model, matches_f_name);
save(matches_f_name, 'matches2d', 'matches3d', 'matches_dist');

%% Estimate pose.
[rotation_mat, translation_mat] = estimate_pose(matches_f_name, model_f_name, query_im_name);
