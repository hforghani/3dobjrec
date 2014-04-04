function estimate_pose()

clearvars; close all;
addpath EPnP;

%% Load data.
matches_f_name = 'data/matches_anchi_test0_t100_kd';
% matches_f_name = 'data/matches_anchiceratops_morethresh';
% matches_f_name = 'data/matches_anchiceratops';
% matches_f_name = 'data/matches_anchiceratops_dense';

model_f_name = 'data/model_anchi_multi_kd';
% model_f_name = 'data/model_anchiceratops_multi';
% model_f_name = 'data/model_anchiceratops_single';

result_f_name = 'data/result_anchi_kd';
% result_f_name = 'data/result_anchiceratops_dense';

test_im_name = [get_dataset_path() '0-24(1)\0-24\anchiceratops\db_img\1090.jpg'];
% test_im_name = 'test/test1.jpg';

matches = load(matches_f_name);
matches2d = matches.matches2d;
matches3d = matches.matches3d;
matches_dist = matches.matches_dist;
match_count = size(matches2d,2);

model = load(model_f_name);
model = model.model;
K = model.get_calib_matrix(); % calibration matrix

%% Run P3P with RANSAC.
corr_data = [matches2d; matches3d(2:4,:)];

t = 100;
s = 3;
[M, inliers] = ransac(corr_data, @epnp_fittingfn, @epnp_distfn, @degenfn , s, t);
rotation_mat = M(:,1:3);
translation_mat = M(:,4);
save(result_f_name, 'rotation_mat', 'translation_mat', 'inliers');

%% Draw inliers.
image = imread(test_im_name);
figure(1);
imshow(image);
hold on;
scatter(matches2d(1,:), matches2d(2,:), 'r', 'filled');
scatter(matches2d(1,inliers), matches2d(2,inliers), 'y', 'filled');

%% Map points with the found transformation.
points2d = model.project_points(rotation_mat, translation_mat);
figure(2);
imshow(image);
hold on;
scatter(matches2d(1,:), matches2d(2,:), 'r', 'filled');
scatter(points2d(1,:), points2d(2,:), 10, 'g', 'filled');

% figure(3);
% scatter(points2d(1,:), points2d(2,:), 10, 'g', 'filled');


function M = epnp_fittingfn(data)
%% Estimate camera position by EPnP.
    count = size(data, 2);
    x3d_h = [data(3:5,:); ones(1,count)];
    x2d_h = [data(1:2,:); ones(1,count)];
    [R, T, ~, ~, ~] = efficient_pnp_gauss(x3d_h', x2d_h', K);
    M = [R, T];
end

function [inliers, M] = epnp_distfn(M, data, t)
%% Get best camera position with maximum number of inliers.
    if ~iscell(M)
        M = {M};
    end
    max_inliers = -1;
    for i = 1:length(M)
        cur_M = M{i};
        R = cur_M(:,1:3);
        T = cur_M(:,4);
        data_count = size(data,2);
        errors = zeros(data_count,1);
        
        for j = 1:data_count
            x = data(:,j);
            point3d = x(3:5);
            point2d = x(1:2);
            error = reprojection_error_usingRT(point3d', point2d', R, T, K);
            errors(j) = error;
        end

        cur_inliers = find(errors < t);
        if length(cur_inliers) > max_inliers
            max_inliers = length(cur_inliers);
            inliers = cur_inliers;
            best_model = cur_M;
        end
    end
    M = best_model;
end

function r = degenfn(data)
%% degeneration function
    r = 0;
end

end


