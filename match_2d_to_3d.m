function [matches2d, matches3d, matches_dist] = match_2d_to_3d(color_im, model, matches_f_name, edge_thresh)
% matches2d : 2*N; points of query image.
% matches3d : points of 3d model.; 4*N, each column: [point_index; point_pos]
% matches_dist : distances of query and model points for matches.
    addpath model;

    tic;

    %% Extract features.
    query_im = single(rgb2gray(color_im));

    % regular matching
    [sift_frames, sift_descriptors] = vl_sift(query_im, 'EdgeThresh' , edge_thresh);

    query_points_num = size(sift_frames, 2);
    fprintf('%d descriptors extracted.\n', query_points_num);

    %% Display features.
    % figure;
    % imshow(I);
    % hold on;
    % 
    % Show some of features.
    % perm = randperm(query_points_num);
    % sel = perm(1:1000);
    % h1 = vl_plotframe(sift_frames(:,sel));
    % h2 = vl_plotframe(sift_frames(:,sel));
    % set(h1,'color','k','linewidth',3);
    % set(h2,'color','y','linewidth',2);

    %% Register 2d to 3d.
    max_error = 110;
    max_color_dist = 20;

    matches2d = [];
    matches3d = [];
    matches_dist = [];

    % Iterate on query image key points.
    camera_count = length(model.cameras);
    for feature_index = 1:query_points_num
    %     tic;
        query_f = sift_frames(:,feature_index);
        query_d = sift_descriptors(:,feature_index);
        query_pos = query_f(1:2,1);
        query_color = color_im(round(query_pos(2)), round(query_pos(1)), :);
        query_color = double(reshape(query_color, 3,1));

        good_point_indices = [];
        good_point_dist = [];
    
        % Iterate on cameras.
        for camera_index = 1:camera_count
            cam = model.cameras{camera_index};
            % Match by color.
%             is_matched = match_by_color(cam.multi_desc_point_indexes, query_color, max_color_dist, model);
%             multiscale_desc = cam.multiscale_desc(:,is_matched);
%             multi_desc_point_indexes = cam.multi_desc_point_indexes(:,is_matched);
            multiscale_desc = cam.multiscale_desc;
            multi_desc_point_indexes = cam.multi_desc_point_indexes;
            % Match by descriptor.
            desc_count = size(multiscale_desc, 2);
            dif = double(multiscale_desc) - double(repmat(query_d, 1, desc_count));
            dif_norms = sqrt(sum(dif .^ 2));
            low_errors = dif_norms(dif_norms < max_error);
            low_err_indexes = multi_desc_point_indexes(dif_norms < max_error);
            good_point_dist = [good_point_dist low_errors];
            good_point_indices = [good_point_indices low_err_indexes];
        end

        min_dist = [];
        % Add best match to the matches.
        if ~isempty(good_point_indices)
            [min_dist, i] = min(good_point_dist);
            min_index = good_point_indices(i);
            matches2d = [matches2d, query_pos];
            pt = model.points{min_index};
            matches3d = [matches3d, [min_index; pt.pos]];
            matches_dist = [matches_dist, min_dist];
            fprintf('\n====== Matched: (%f, %f) to point %d : %f ======\n\n', ...
                query_f(1), query_f(2), min_index, min_dist);
        end
    %     toc;
        fprintf('%i : Query point (%f, %f) done. ', ...
                    feature_index, query_pos(1), query_pos(2));
        if min_dist
            fprintf('Min dist = %f.\n', min_dist);
        else
            fprintf('No accepted match.\n');
        end

        % Save in determined intervals.
        if mod(feature_index, 100) == 0
            save(matches_f_name, 'matches2d', 'matches3d', 'matches_dist');        
        end

    end

    toc;
end


function is_filtered = match_by_color(point_indexes, color, threshold, model)
% point_indexes: indexes of some points.
% color: match color.
% threshold: threshold of color difference.
% is_filtered: binary result of filter
    uniq_indexes = unique(point_indexes);
    pt_count = length(point_indexes);
    colors = zeros(3, pt_count);
    for i = 1:length(uniq_indexes)
        index = uniq_indexes(i);
        col = model.points{index}.color;
        colors(1, point_indexes == index) = col(1);
        colors(2, point_indexes == index) = col(2);
        colors(3, point_indexes == index) = col(3);
    end
    dif = colors - repmat(color, 1, pt_count);
    dif_norms = sum(dif .^ 2) .^ 0.5;
    is_filtered = dif_norms < threshold;
end
