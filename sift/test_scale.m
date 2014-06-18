addpath('../');
addpath('../model');
load('../data/model/blackbeard');
cam = model.cameras{3};
[poses, ~] = cam.get_points_poses(model.points, model.calibration);
model_path = [get_dataset_path() '0-24(1)\0-24\blackbeard\'];
im = cam.get_image(model_path);
% im = imread('cameraman.tif');
if size(im, 3) == 3
    im = rgb2gray(im);
end
im = double(im) / 255.0;

scale = lowe_sift_scale(im, poses, 1, floor(log2(min(size(im)))), 10);
fprintf('%d scales found out of %d\n', length(find(scale)), size(poses,2));
% [ pos, scale, orient, desc ] = lowe_sift(im, 2);
