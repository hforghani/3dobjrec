function [query_frames, correspondences, points, corr_dist] = match_2d_to_3d(color_im, desc_model, models)
% query_frames : 4*N; data of keypoints extracted from 
% correspondences : 2*M matrix; each column is an array of [query_pos_index; point_index_in_points_array]
% points: 2*P; points of 3d model; each column is in the format [model_index, point_index]
% corr_dist: 1*M matrix of correspondences descriptor distances
addpath model;

% Extract keypoints using SIFT.
fprintf('extracting feature from query image ... ');
query_im = single(rgb2gray(color_im));    
[query_frames, ~] = vl_sift(query_im, 'Levels', 3, 'EdgeThresh' , 10);

%     figure; imshow(color_im); hold on;
%     h2 = vl_plotframe(query_frames) ;
%     set(h2,'color','y','linewidth',1) ;

query_poses = query_frames(1:2, :);
[query_poses, u_indexes, ~] = unique(query_poses', 'rows'); % Remove repeated points.
query_poses = query_poses';
query_frames = query_frames(:, u_indexes);

% Calcualate Daisy descriptor of keypoints.
query_descriptors = devide_and_compute_daisy(query_im, query_poses);
zero_indexes = find(~any(query_descriptors));
query_descriptors(:, zero_indexes) = [];
query_frames(:, zero_indexes) = [];
fprintf('done\n');

query_points_num = size(query_descriptors, 2);
fprintf('%d descriptors extracted.\n', query_points_num);

% Register 2d to 3d. Find some nearest neighbors for each query pose.
fprintf('registering 2d to 3d ... ');
max_error = 0.7;
col_thr = 50;
models_count = length(unique(desc_model.desc_model_indexes));
nei_num = ceil(models_count/10);
[indexes, distances] = vl_kdtreequery(desc_model.kdtree, double(desc_model.descriptors), query_descriptors, 'NUMNEIGHBORS', nei_num);

% Filter high errors and determine points.
is_less_than_error = distances < max_error;
has_same_color = match_color(query_frames(1:2,:), indexes, color_im, desc_model, models, col_thr);
retained = is_less_than_error & has_same_color;
point_general_indexes = unique(indexes(retained));
points_count = length(point_general_indexes);
points = [desc_model.desc_model_indexes(point_general_indexes);
          desc_model.desc_point_indexes(point_general_indexes)];

% Determine correspondences and their distances.
corr_count = sum(sum(retained));
correspondences = zeros(2, corr_count);
corr_dist = zeros(1, corr_count);
corr_i = 1;
for i = 1 : size(indexes,2)
    indexes_i = indexes(:,i);
    match_count = sum(retained(:,i));
    correspondences(1, corr_i : corr_i+match_count-1) = i;
    correspondences(2, corr_i : corr_i+match_count-1) = indexes_i(retained(:,i));
    corr_dist(corr_i : corr_i+match_count-1) = distances(retained(:,i), i);
    corr_i = corr_i + match_count;
end

% Set second row of correspondences equal to the index of point column in 'points' array.
addpath utils;
correspondences(2,:) = reindex_arr(point_general_indexes, correspondences(2,:));

% Correct references in correspondences which will be removed.
corrected = false(1, points_count);
for i = 1:points_count
    repeated_indexes = find(points(1,:) == points(1,i) & points(2,:) == points(2,i));
    if length(repeated_indexes) > 1 && ~corrected(i)
        is_related_corr = ismember(correspondences(2,:), repeated_indexes);
        correspondences(2, is_related_corr) = i;
        corrected(repeated_indexes) = true;
    end
end

% Remove repeated points.
points_ids = 1:size(points,2);
[new_points, i_p, ~] = unique(points', 'rows');
points_ids = points_ids(i_p);
points = new_points';

% Change references as they refer to the related column of points.
correspondences(2,:) = reindex_arr(points_ids, correspondences(2,:));

% Remove repeated correspondences.
[new_corr, ~, ~] = unique(correspondences', 'rows');
correspondences = new_corr';

fprintf('done\n');




function is_match = match_color(poses, indexes, im, desc_model, models, thresh)

is_match = false(size(indexes));

for i = 1:size(poses,2)
    x = round(poses(2,i));
    y = round(poses(1,i));
    patch = im(max(x-1,1):min(x+1,size(im,1)), max(y-1,1):min(y+1,size(im,2)), :);
    col = reshape(mean(mean(patch, 1), 2), 3,1);
    
    match_i = indexes(:,i);
    for j = 1:length(match_i)
        model_i = desc_model.desc_model_indexes(match_i(j));
        point_i = desc_model.desc_point_indexes(match_i(j));
        is_match(j,i) = norm(models{model_i}.points{point_i}.color - col) < thresh;
    end
end
