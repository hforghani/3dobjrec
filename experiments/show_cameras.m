close all;
addpath model;
obj_name = 'bengal_tiger';
load(['data/model/' obj_name]);

cam_poses = zeros(3, length(model.cameras));
test_poses = zeros(3, length(model.cameras));
for i = 1:length(model.cameras)
    cam = model.cameras{i};
    cam_poses(:, i) = cam.center;
    test_poses(:, i) = cam.rotation_matrix() \ [0 0 2]' + cam.center;
end

scatter3(cam_poses(1,:), cam_poses(2,:), cam_poses(3,:), 10, 'filled', 'MarkerFaceColor', 'b');
hold on;
scatter3(test_poses(1,:), test_poses(2,:), test_poses(3,:), 10, 'filled', 'MarkerFaceColor', 'r');

poses = model.get_poses();
scatter3(poses(1,1:500), poses(2,1:500), poses(3,1:500), 4, 'filled', 'MarkerFaceColor', 'g');

xlabel('x');
ylabel('y');
zlabel('z');
