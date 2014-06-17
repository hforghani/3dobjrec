% close all;
% % run('VLFEATROOT/toolbox/vl_setup');
% 
% test_im_name = 'test/test2.jpg';
% edge_thresh = 10;
% 
% %% Extract features.
% image = imread(test_im_name);
% gray_im1 = single(rgb2gray(image));
% 
% % differnet scale
% [x,y] = size(gray_im1);
% gray_im2 = gray_im1(1:2:x, 1:2:y);
% 
% frames1 = repmat([100;100;0;0], 1, 21);
% frames1(3,:) = 1:0.1:3;
% [fr1, desc1] = vl_sift(gray_im1, 'frames', frames1, 'orientations');
% 
% frames2 = repmat([50;50;0;0], 1, 21);
% frames2(3,:) = 1:0.1:3;
% [fr2, desc2] = vl_sift(gray_im2, 'frames', frames2, 'orientations');
% 
% %% Find best match for each scale.
% for i = 1:size(fr1,2)
%     desc = desc1(:,i);
%     dif = double(desc2) - double(repmat(desc, 1, size(desc2,2)));
%     dist = sqrt(sum(dif .^ 2));
%     [min_dist, min_i] = min(dist);
% 
%     fprintf('scale %f matched with %f with distance %f\n', ...
%         fr1(3,i), fr2(3,min_i), min_dist);
% end

%% Test sift scale search.
addpath test_code;
addpath model;
% load 'data/model/axe_knight';
cam = model.cameras{1};
% image = imread([get_dataset_path() '0-24(1)\0-24\axe_knight\db_img\' cam.file_name]);
model_path = [get_dataset_path() '0-24(1)\0-24\anchiceratops\'];
image = cam.get_image(model_path);
gray_im = rgb2gray(image);
tic;
[frame, desc] = vl_sift(single(gray_im), 'Octaves', 8, 'Levels', 15, 'EdgeThresh', 50);
% points = detectSURFFeatures(gray_im, 'MetricThreshold', 0);
% [features, valid_points] = extractFeatures(gray_im, points);
toc;

desc_poses = frame(1:2,:);
% desc_poses = double(valid_points.Location');
kdtree = vl_kdtreebuild(double(desc_poses));

measurements = cam.get_measurements(model.points);
poses = zeros(2, length(measurements));
for i = 1:length(measurements)
    poses(:,i) = measurements{i}.get_pos_in_camera(model.calibration);
end
[indexes, dist] = vl_kdtreequery(kdtree, desc_poses, poses);
imshow(image); hold on;
scatter(desc_poses(1,:), desc_poses(2,:), 5, 'r', 'filled');
scatter(poses(1,:), poses(2,:), 30, 'g');
