function filtered_indexes = filter_corr(matches2d, matches3d, match_model_indexes, match_point_indexes)

models = unique(match_model_indexes);
model_count = length(models);
filtered_indexes = [];

for i = 1 : model_count
    model = models(i);
    model_indexes = match_model_indexes == model;
    model_real_indexes = find(model_indexes);
    model_matches2d = matches2d(:, model_indexes);
    kdtree = vl_kdtreebuild(double(model_matches2d));
    
    [~, distances] = vl_kdtreequery(kdtree, model_matches2d, model_matches2d, 'NUMNEIGHBORS', 2);
    nearest_nei = distances(2, :);
    model_filtered_indexes = nearest_nei < 100;
    filtered_indexes = [filtered_indexes, model_real_indexes(model_filtered_indexes)];
end



end

function conf = hyp_confidence(matches2d, matches3d, match_point_indexes, mdl_points)
% Calculate confidence of a hypothesis.

    % 2d local consistency
    nei_thr_2d = 100;
    match_count = size(matches2d, 2);
    kdtree = vl_kdtreebuild(double(matches2d));
    nei_num = floor(size(matches2d, 2) / 20);
    [nei2d_indexes, distances2d] = vl_kdtreequery(kdtree, matches2d, matches2d, 'NUMNEIGHBORS', nei_num);
    nei2d_indexes(distances2d > nei_thr_2d) = 0;
%     distances2d(distances2d > nei_thr_2d) = 0;
    local_sup_count = zeros(match_count, 1);
    
    % 3d local consistency
    nei_thr_3d = 2;
    for i = 1:match_count
        % Find spatially close points.
        nn_i = nei2d_indexes(:, i);
        nn_i = nn_i(nn_i ~= 0);
        nn_poses = zeros(3, length(nn_i));
        nn_points = cell(1, length(nn_i));
        for j = 1:length(nn_i)
            point_index = match_point_indexes(nn_i(j));
            nn_points{j} = mdl_points{point_index};
            nn_poses(:, j) = mdl_points{point_index}.pos;
        end
        pos3d = matches3d(:, i);
        distances3d = sum((nn_poses - repmat(pos3d, 1, length(nn_poses))) .^ 2);
%         nn3d_i = nn_i(distances3d < nei_thr_3d);
        nn_points = nn_points{distances3d < nei_thr_3d};
        
        % Find co-visible points.
        cur_point_index = match_point_indexes(i);
        point = mdl_points{cur_point_index};
        is_covis = point.is_covisible_with(nn_points);
%         nn_points = nn_points(is_covis);
        local_sup_count = sum(is_covis);
    end
    
    conf = sum(local_sup_count);
end
