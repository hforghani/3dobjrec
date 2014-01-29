clearvars; close all;
addpath EPnP;

%% Load data.
matches_f_name = 'data/matches_anchiceratops';
% matches_f_name = 'data/matches_anchiceratops_dense';

model_f_name = 'data/model_anchiceratops_multi';
% model_f_name = 'data/model_anchiceratops_single';

result_f_name = 'data/result_anchiceratops';
% result_f_name = 'data/result_anchiceratops_dense';

test_im_name = 'test.jpg';

matches = load(matches_f_name);
matches2d = matches.matches2d;
matches3d = matches.matches3d;
matches_dist = matches.matches_dist;
match_count = size(matches2d,2);

model = load(model_f_name);
model = model.model;
cal = model.calibration;
K = [1 0 cal.cx; 0 cal.fy/cal.fx cal.cy; 0 0 1]; % intrinsic parameters matrix

%% Draw matches.
image = imread(test_im_name);
figure(1);
imshow(image);
hold on;
scatter(matches2d(1,:), matches2d(2,:), 'r', 'filled');
for i = 1:match_count
    text(matches2d(1,i), matches2d(2,i), num2str(i), 'Color', 'y');
end

disp('Select a key point on the image.');
%% Select points in matches.
figure(1);
count = 5;
x3d_h = zeros(4,count);
x2d_h = zeros(3,count);
[x,y] = ginput(count);
min_dist = -1;
sel_index = -1;
for j = 1:count
    point = [x(j); y(j)];
    for i = 1:match_count
        dist = norm(matches2d(:,i) - point);
        if min_dist == -1 || dist < min_dist
            min_dist = dist;
            sel_index = i;
        end
    end
    x3d_h(:,j) = [matches3d(2:4,sel_index); 1];
    x2d_h(:,j) = [matches2d(:,sel_index); 1];
end
scatter(x2d_h(1,:), x2d_h(2,:), 'gx');

K = model.get_calib_matrix();
[R, T, ~, ~, ~] = efficient_pnp_gauss(x3d_h', x2d_h', K);

points2d = model.project_points(R, T);
scatter(points2d(1,:), points2d(2,:), 10, 'g', 'filled');

%% Map and draw points with the found transformation.
figure(3);
scatter(points2d(1,:), points2d(2,:), 10, 'g', 'filled');

points3d = model.transform_points(R, T);
figure(4);
scatter3(points3d(1,:), points3d(2,:), points3d(3,:), 10, 'g', 'filled');

error = reprojection_error_usingRT(x3d_h(1:3,:)', x2d_h(1:2,:)', R, T, K);
fprintf('error = %f\n', error);
