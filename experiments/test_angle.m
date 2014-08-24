addpath utils;

% close all;
% figure;
% xlabel('x'); ylabel('y'); zlabel('z');
% hold on;

N = 10000;
radius = 10;


% Sample 3 points on the plane.

points = [rand(2, 3) * 2 - 1; ones(1,3) * radius];
main_angle = middle_angle(points);


% Sample N cameras.

phi_z = rand(N,1) * 2*pi;
cos_phi_x = rand(N,1);

load('data/model/airborne_soldier.mat');
K = model.calibration.get_calib_matrix();

centers = zeros(3,N);
poses = zeros(3,N);
dist = zeros(1,N);

for i = 1 : N
    phi_x = acos(cos_phi_x(i));
    R = rot_matrix([1 0 0], phi_x) * rot_matrix([0 0 1], phi_z(i));
    C = (eye(3) - inv(R)) * [0 0 radius]';

    % Show direction of cameras.
    p = R \ [0 0 2]' + C;
    centers(:,i) = C;
    poses(:,i) = p;
%     line([C(1) p(1)], [C(2) p(2)], [C(3) p(3)]);

    proj_points = R * points - R * repmat(C, 1, 3);
    dist(i) = abs(middle_angle(proj_points) - main_angle);
end

% scatter3(centers(1,:), centers(2,:), centers(3,:), 20, 'b', 'filled');
% scatter3(points(1,:), points(2,:), points(3,:), 50, 'r', 'filled');

figure;
hist(dist, 20);
title(sprintf('main angle = %f', main_angle * 180 / pi));
