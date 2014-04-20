function [matches2d, matches3d, matches_dist] = match_2d_to_3d(color_im, desc_model, points, matches_f_name)
% matches2d : 2*N; points of query image.
% matches3d : points of 3d model.; 4*N, each column: [point_index; point_pos]
% matches_dist : distances of query and model points for matches.
    addpath model;

    tic;

    %% Extract features.
    fprintf('extracting feature from query image ... ');
    query_im = single(rgb2gray(color_im));
    % dense sampling: %
%     [h, w] = size(query_im);
% 	step = 3;
% 	w_count = ceil(w/step) - 1;
% 	h_count = ceil(h/step) - 1;
% 	points = zeros(2, w_count * h_count);
% 	x = 0;
% 	for i = 1 : w_count
% 		x = x + step;
%         y = 0;
% 		for j = 1 : h_count
% 			y = y + step;
% 			points(:, (i-1)*h_count + j) = [x; y];
% 		end
%     end
    % Use SIFT key-points:
    edge_thresh = 20;
    [sift_frames, ~] = vl_sift(query_im, 'EdgeThresh' , edge_thresh);
    query_points = sift_frames(1:2, :);
    query_descriptors = devide_and_compute_daisy(query_im, query_points);
    zero_indexes = find(~any(query_descriptors));
    query_descriptors(:, zero_indexes) = [];
    query_points(:, zero_indexes) = [];
    fprintf('done\n');

    % sift_descriptors = double(sift_descriptors);
    query_points_num = size(query_descriptors, 2);
    fprintf('%d descriptors extracted.\n', query_points_num);

    %% Register 2d to 3d.
    max_error = 1;
%     max_color_dist = 20;

    matches2d = [];
    matches3d = [];
    matches_dist = [];

    % Iterate on query image key points.
    for feature_index = 1:query_points_num
        query_d = query_descriptors(:,feature_index);
        query_pos = query_points(:,feature_index);

        % Match by color.
%             is_matched = match_by_color(cam.multi_desc_point_indexes, query_color, max_color_dist, model);
%             multiscale_desc = cam.multiscale_desc(:,is_matched);
%             multi_desc_point_indexes = cam.multi_desc_point_indexes(:,is_matched);
        % Match by descriptor.
        [index, distance] = vl_kdtreequery(desc_model.kdtree, double(desc_model.descriptors), query_d);
        if distance < max_error
%             good_point_dist = [good_point_dist, distance];
%             good_point_indices = [good_point_indices, cam.multi_desc_point_indexes(index)];
            point_index = desc_model.desc_point_indexes(index);
            matches2d = [matches2d, query_pos];
            pt = points{point_index};
            matches3d = [matches3d, [point_index; pt.pos]];
            matches_dist = [matches_dist, distance];
            fprintf('%i :  ====== Matched: (%f, %f) to point %d , dist = %f ======\n\n', ...
                feature_index, query_pos(1), query_pos(2), point_index, distance);
        end
        if distance >= max_error
            fprintf('%i : (%f, %f) , dist = %f. No match.\n', ...
                        feature_index, query_pos(1), query_pos(2), distance);
        end
        % Save in determined intervals.
        if mod(feature_index, 100) == 0
            save(matches_f_name, 'matches2d', 'matches3d', 'matches_dist');        
        end
    end

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
