function [matches2d, matches3d, matches_dist] = match_2d_to_3d(I, model)
% matches2d : 2*N ; matches of query image.
% matches3d : cell array of Point instances of size N*1.
% matches_dist : distances of query and model points for matches.
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
matches_dist = [];
max_error = 100;

% Iterate on query image key points.
for feature_index = 1:query_points_num
    tic;
    query_f = sift_frames(:,feature_index);
    query_d = sift_descriptors(:,feature_index);
    point_pos = query_f(1:2,1);

    % Iterate on 3d points.
    good_point_indices = [];
    good_point_dist = [];
    all_point_dist = [];
    for point_index = 1:points_num
        pt = model.points{point_index};
        % Iterate on 3d point measurements.
        for measure_i = 1:pt.measure_num
            meas = pt.measurements{measure_i};
            [f, d, dist] = meas.get_best_match_to_multiscale(query_f, query_d);
%             [d, dist] = meas.get_best_match_to_singlescale(query_d);
            all_point_dist = [all_point_dist; dist];
            if dist < max_error
                good_point_indices = [good_point_indices; point_index];
                good_point_dist = [good_point_dist; dist];
                break;
            end
        end
    end
    
    % Add best match to the matches.
    if ~isempty(good_point_indices)
        [min_dist, i] = min(good_point_dist);
        min_index = good_point_indices(i);
        matches2d = [matches2d, point_pos];
        pos = model.points{min_index}.pos;
        matches3d = [matches3d, pos];
        matches_dist = [matches_dist, min_dist];
        fprintf('\n====== Matched: (%f, %f) to (%f, %f, %f) : %f ======\n', ...
            query_f(1), query_f(2), pos(1), pos(2), pos(3), min_dist);
    else
        min_dist = min(all_point_dist);
    end
    toc;
    fprintf('%i : query point (%f, %f) with min dist %f done.\n', ...
        feature_index, point_pos(1), point_pos(2), min_dist);
end
