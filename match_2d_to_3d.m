function [matches2d, matches3d, matches_dist] = match_2d_to_3d(color_im, model, matches_f_name, edge_thresh)
% matches2d : 2*N; points of query image.
% matches3d : points of 3d model.; 4*N, each column: [point_index; point_pos]
% matches_dist : distances of query and model points for matches.
addpath model;

tic;

%% Extract features.
% parameters for dense matching.
step = 2;
bin_size = 3.6;

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
max_error = 100;
max_color_dist = 20;

points_num = length(model.points);
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

    % Iterate on 3d points.
    good_point_indices = [];
    good_point_dist = [];
    all_point_dist = [];
    for point_index = 1:points_num
        pt = model.points{point_index};
        if norm(pt.color - query_color) > max_color_dist
            continue;
        end
        % Iterate on 3d point measurements.
        for measure_i = 1:pt.measure_num
            meas = pt.measurements{measure_i};
            
            [f, d, dist] = meas.get_best_match_to_multiscale(query_f, query_d);
            
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
        matches2d = [matches2d, query_pos];
        pt = model.points{min_index};
        matches3d = [matches3d, [min_index; pt.pos]];
        matches_dist = [matches_dist, min_dist];
        fprintf('\n====== Matched: (%f, %f) to (%f, %f, %f) : %f ======\n\n', ...
            query_f(1), query_f(2), pt.pos(1), pt.pos(2), pt.pos(3), min_dist);
    else
        min_dist = min(all_point_dist);
    end
%     toc;
    fprintf('%i : Query point (%f, %f) done. ', ...
                feature_index, query_pos(1), query_pos(2));
    if min_dist
        fprintf('Min dist = %f.\n', min_dist);
    else
        fprintf('No color match.\n');
    end
    
    % Save in determined intervals.
    if mod(feature_index, 100) == 0
        save(matches_f_name, 'matches2d', 'matches3d', 'matches_dist');        
    end
end

toc;
