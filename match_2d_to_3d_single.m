function [matches2d, matches3d, matches_dist] = match_2d_to_3d_single(color_im, model, matches_f_name, scale)
% matches2d : 2*N; points of query image.
% matches3d : points of 3d model.; 4*N, each column: [point_index; point_pos]
% matches_dist : distances of query and model points for matches.
    addpath model;

    tic;

    %% Extract features.
    % parameters for dense matching.
    step = 4;
    magnif = 3;
    bin_size = scale * magnif;

    query_im = single(rgb2gray(color_im));

    % dense matching
    [sift_frames, sift_descriptors] = vl_dsift(query_im, 'size', bin_size, 'step', step);
    sift_frames(3,:) = scale;
    sift_frames(4,:) = 0;

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
    max_error = 30;
    max_color_dist = 20;

    camera_count = length(model.cameras);
    matches2d = [];
    matches3d = [];
    matches_dist = [];

    % Iterate on query image key points.
    for feature_index = 1:query_points_num
    %     tic;
        query_f = sift_frames(:,feature_index);
        query_d = sift_descriptors(:,feature_index);
        query_pos = query_f(1:2,1);
        query_color = color_im(round(query_pos(2)), round(query_pos(1)), :);
        query_color = double(reshape(query_color, 3,1));

        good_point_indices = [];
        good_point_dist = [];
        all_point_dist = [];

        % Iterate on cameras.
        for camera_index = 1:camera_count
            cam = model.cameras{camera_index};
            % Match by color.
%             is_matched = match_by_color(cam.single_desc_point_indexes, query_color, max_color_dist, model);
%             singlescale_desc = cam.singlescale_desc(:,is_matched);
%             single_desc_point_indexes = cam.single_desc_point_indexes(:,is_matched);
            singlescale_desc = cam.singlescale_desc;
            single_desc_point_indexes = cam.single_desc_point_indexes;
            % Match by descriptor.
            desc_count = size(singlescale_desc, 2);
            dif = double(singlescale_desc) - repmat(double(query_d), 1, desc_count);
            dif_norms = sum(dif .^ 2) .^ 0.5;
            low_errors = dif_norms(dif_norms < max_error);
            low_err_indexes = single_desc_point_indexes(dif_norms < max_error);
            good_point_dist = [good_point_dist low_errors];
            good_point_indices = [good_point_indices low_err_indexes];
        end

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
        else
            min_dist = min(all_point_dist);
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
    pt_count = length(point_indexes);
    colors = zeros(3, pt_count);
    for i = 1:pt_count
        colors(:,i) = model.points{point_indexes(i)}.color;
    end
    dif = colors - repmat(color, 1, pt_count);
    dif_norms = sum(dif .^ 2) .^ 0.5;
    is_filtered = dif_norms < threshold;
end
