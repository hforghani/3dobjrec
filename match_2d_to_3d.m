function [matches2d, matches3d, match_model_indexes, match_point_indexes, matches_dist] = ...
    match_2d_to_3d(color_im, desc_model, model_points)
% matches2d : 2*N; points of query image.
% matches3d : points of 3d model.; 4*N, each column: [point_index; point_pos]
% matches_dist : distances of query and model points for matches.
    addpath model;

    tic;

    %% Extract features.
    fprintf('extracting feature from query image ... ');
    query_im = single(rgb2gray(color_im));
    
    % dense sampling:
%     [h, w] = size(query_im);
% 	step = 3;
% 	w_count = ceil(w/step) - 1;
% 	h_count = ceil(h/step) - 1;
%     [x, y] = meshgrid(step:step:w_count, step:step:h_count);
% 	points = [reshape(x, 1, w_count * h_count); reshape(y, 1, w_count * h_count)];
    
    % Use SIFT key-points:
    edge_thresh = 50;
    [sift_frames, ~] = vl_sift(query_im, 'EdgeThresh' , edge_thresh);
    query_points = sift_frames(1:2, :);
    query_descriptors = devide_and_compute_daisy(query_im, query_points);
    zero_indexes = find(~any(query_descriptors));
    query_descriptors(:, zero_indexes) = [];
    query_points(:, zero_indexes) = [];
    fprintf('done\n');

    query_points_num = size(query_descriptors, 2);
    fprintf('%d descriptors extracted.\n', query_points_num);

    %% Register 2d to 3d.
    fprintf('registering 2d to 3d ... ');
    max_error = 0.7;
%     max_color_dist = 20;

    [indexes, distances] = vl_kdtreequery(desc_model.kdtree, double(desc_model.descriptors), query_descriptors);
    match_indexes = distances < max_error;
    matches2d = query_points(:, match_indexes);
    match_model_indexes = desc_model.desc_model_indexes(indexes(match_indexes));
    match_point_indexes = desc_model.desc_point_indexes(indexes(match_indexes));
    matches3d = zeros(3, length(match_point_indexes));
    for i = 1:length(match_point_indexes)
        model_index = match_model_indexes(i);
        points = model_points{model_index};
        matches3d(:, i) = points{match_point_indexes(i)}.pos;
    end
    matches_dist = distances(match_indexes);

    fprintf('done\n');
    toc;
end


% function is_filtered = match_by_color(point_indexes, color, threshold, model)
% % point_indexes: indexes of some points.
% % color: match color.
% % threshold: threshold of color difference.
% % is_filtered: binary result of filter
%     uniq_indexes = unique(point_indexes);
%     pt_count = length(point_indexes);
%     colors = zeros(3, pt_count);
%     for i = 1:length(uniq_indexes)
%         index = uniq_indexes(i);
%         col = model.points{index}.color;
%         colors(1, point_indexes == index) = col(1);
%         colors(2, point_indexes == index) = col(2);
%         colors(3, point_indexes == index) = col(3);
%     end
%     dif = colors - repmat(color, 1, pt_count);
%     dif_norms = sum(dif .^ 2) .^ 0.5;
%     is_filtered = dif_norms < threshold;
% end
