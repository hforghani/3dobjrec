function [query_poses, correspondences, points] = match_2d_to_3d(color_im, desc_model)
% query_poses : 2*N; points of query image.
% correspondences : 2*M matrix; each column is an array of [query_pos_index; point_index_in_points_array]
% points: 2*P; points of 3d model; each column is in the format [model_index, point_index]
    addpath model;

    %% Extract features.
    fprintf('extracting feature from query image ... ');
    query_im = single(rgb2gray(color_im));
    
    % dense sampling:
%     [h, w] = size(query_im);
% 	step = 3;
%     [x, y] = meshgrid(step : step : w - step, step : step : h - step);
% 	query_points = [x(:), y(:)]';
    
    % Use SIFT key-points:
    edge_thresh = 100;
    [sift_frames, ~] = vl_sift(query_im, 'EdgeThresh' , edge_thresh);
    query_poses = sift_frames(1:2, :);
    query_poses = unique(query_poses', 'rows')'; % Remove repeated points.

    query_descriptors = devide_and_compute_daisy(query_im, query_poses);
    zero_indexes = find(~any(query_descriptors));
    query_descriptors(:, zero_indexes) = [];
    query_poses(:, zero_indexes) = [];
    fprintf('done\n');

    query_points_num = size(query_descriptors, 2);
    fprintf('%d descriptors extracted.\n', query_points_num);

    %% Register 2d to 3d.
    fprintf('registering 2d to 3d ... ');
    max_error = 0.7;

    % Match 2d to 3d; some nearest neighbors for each query pose.
    [indexes, distances] = vl_kdtreequery(desc_model.kdtree, double(desc_model.descriptors), query_descriptors, 'NUMNEIGHBORS', 2);
    
    % Filter high errors and determine points.
    is_less_than_error = distances < max_error;
    point_general_indexes = unique(indexes(is_less_than_error));
    points_count = length(point_general_indexes);
    points = zeros(2, points_count);
    for i = 1:points_count
        points(1, i) = desc_model.desc_model_indexes(point_general_indexes(i));
        points(2, i) = desc_model.desc_point_indexes(point_general_indexes(i));
    end
    
    % Construct correspondences.
    correspondences = zeros(2, sum(sum(is_less_than_error)));
    corr_i = 1;
    for i = 1:size(is_less_than_error,2)
        indexes_i = indexes(:,i);
        match_count = sum(is_less_than_error(:,i) == 1);
        correspondences(1, corr_i : corr_i+match_count-1) = i;
        correspondences(2, corr_i : corr_i+match_count-1) = indexes_i(1 : match_count);
        corr_i = corr_i + match_count;
    end
    
    % Set second row of correspondences to the index of point column in 'points' array.
    new_point_indexes = zeros(1, length(point_general_indexes));
    for i = 1:length(point_general_indexes)
        new_point_indexes(correspondences(2,:) == point_general_indexes(i)) = i;
    end
    correspondences(2,:) = new_point_indexes;

    fprintf('done\n');
end

