close all;
% run('VLFEATROOT/toolbox/vl_setup');

test_im_name = 'test/test2.jpg';
edge_thresh = 10;

%% Extract features.
image = imread(test_im_name);
gray_im1 = single(rgb2gray(image));

% differnet scale
[x,y] = size(gray_im1);
gray_im2 = gray_im1(1:2:x, 1:2:y);

frames1 = repmat([100;100;0;0], 1, 21);
frames1(3,:) = 1:0.1:3;
[fr1, desc1] = vl_sift(gray_im1, 'frames', frames1, 'orientations');

frames2 = repmat([50;50;0;0], 1, 21);
frames2(3,:) = 1:0.1:3;
[fr2, desc2] = vl_sift(gray_im2, 'frames', frames2, 'orientations');

%% Find best match for each scale.
for i = 1:size(fr1,2)
    desc = desc1(:,i);
    dif = double(desc2) - double(repmat(desc, 1, size(desc2,2)));
    dist = sqrt(sum(dif .^ 2));
    [min_dist, min_i] = min(dist);

    fprintf('scale %f matched with %f with distance %f\n', ...
        fr1(3,i), fr2(3,min_i), min_dist);
end

% %% Display features.
% show_descriptors(gray_im1, fr1);
% show_descriptors(gray_im2, fr2);
