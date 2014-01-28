function [matches2d, matches3d] = match_2d_to_3d(I, model)
% matches: [2dpoints, 3dpoints] where 2dpoints is 2*N and 3dpoints is a
% cell array of Point instances of size N*1.
addpath model;

%% Extract features.
query_im = single(rgb2gray(I));

% bin_size = 8;
% magnif = 3;
% [sift_frames, sift_descriptors] = vl_dsift(query_im, 'size', bin_size, 'step', 5);
% sift_frames(3,:) = bin_size / magnif ;
% sift_frames(4,:) = 0;
[sift_frames, sift_descriptors] = vl_sift(query_im);

query_points_num = size(sift_frames, 2);
fprintf('%d descriptors extracted.\n', query_points_num);

%% Display features.
figure;
imshow(I);
hold on;

% Show some of features.
perm = randperm(query_points_num);
sel = perm(1:1000);
h1 = vl_plotframe(sift_frames(:,sel));
h2 = vl_plotframe(sift_frames(:,sel));
set(h1,'color','k','linewidth',3);
set(h2,'color','y','linewidth',2);

%% Register 2d to 3d.
points_num = length(model.points);
matches2d = [];
matches3d = [];
distances = [];
max_error = 100;

% Iterate on query image key points.
for feature_index = 1:query_points_num
    tic;
    query_f = sift_frames(:,feature_index);
    query_d = sift_descriptors(:,feature_index);
    point_pos = query_f(1:2,1);

    % Iterate on points.
    for point_index = 1:points_num
        pt = model.points{point_index};
        point_dist = zeros(pt.measure_num, 1);
        % Iterate on 3d point measurements.
        for measure_i = 1:pt.measure_num
            meas = pt.measurements{measure_i};
            [f, d, dist] = meas.get_best_match_to_multiscale(query_f, query_d);
%             [d, dist] = meas.get_best_match_to_singlescale(query_d);
            point_dist(measure_i) = dist;
            if dist < max_error
                matches2d = [matches2d, point_pos];
                matches3d = [matches3d, pt.pos];
                fprintf('\n====== Matched: (%f, %f) to (%f, %f, %f) : %f ======\n', ...
                    query_f(1), query_f(2), pt.pos(1), pt.pos(2), pt.pos(3), dist);
                break;
            end
        end
    end
    min_dist = min(point_dist);
    toc;
    fprintf('%i : query point (%f, %f) with min dist %f done.\n', ...
        feature_index, point_pos(1), point_pos(2), min_dist);
end
