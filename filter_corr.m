function filtered_indexes = filter_corr(matches2d, matches3d, match_model_indexes, match_point_indexes, points_array, query_im_name)

    models_i = unique(match_model_indexes);
    model_count = length(models_i);
    filtered_indexes = [];

    image = imread(query_im_name);
    figure(1); imshow(image);
    colors = {'r','g','b','c','m','y','k','w'};

    for i = 1 : model_count
        fprintf('validating hyp %d ... ', i);
        model_i = models_i(i);
        is_of_model = match_model_indexes == model_i;
        model_indexes = find(is_of_model);
        model_matches2d = matches2d(:, is_of_model);
        model_matches3d = matches3d(:, is_of_model);
        model_point_indexes = match_point_indexes(is_of_model);
        adj_mat = hyp_cons_graph(model_matches2d, model_matches3d, model_point_indexes, points_array{model_i});
        confidence = sum(sum(adj_mat));
        
        figure(1); hold on;
        gplot(adj_mat, model_matches2d', ['-o' colors{mod(i,length(colors))}]);
        
        fprintf('done, confidence = %d, ', confidence);
        
        conf_thr = size(model_matches2d,2) / 3;
        if confidence > conf_thr
            adj_path_3 = adj_mat ^ 3;
            diagonal = diag(adj_path_3) > 2;
            is_in_3complete = model_indexes(diagonal);
            filtered_indexes = [filtered_indexes, is_in_3complete];
            scatter(model_matches2d(1, diagonal), model_matches2d(2, diagonal), 'filled', 'MarkerFaceColor', colors{mod(i,length(colors))});
            
            fprintf('accepted\n');
        else
            fprintf('rejected\n');
        end
    end

end

function adj_mat = hyp_cons_graph(matches2d, matches3d, match_point_indexes, mdl_points)
% Get a graph which the nodes are points and there is an edge between two
% each consistent nodes.

    % 2d local consistency
    nei_thr_2d = 50 ^ 2;
    nei_num = 20;
    match_count = size(matches2d, 2);
    kdtree = vl_kdtreebuild(double(matches2d));
    [nei2d_indexes, distances2d] = vl_kdtreequery(kdtree, matches2d, matches2d, 'NUMNEIGHBORS', nei_num);
    nei2d_indexes(distances2d > nei_thr_2d) = 0;
    nei2d_indexes(1, :) = [];
    adj_mat = zeros(match_count);
    
    % 3d local consistency
    nei_thr_3d = 1;
    for i = 1:match_count
        % Find spatially close points.
        nn_i = nei2d_indexes(:, i);
        nn_i = nn_i(nn_i ~= 0);
        if ~isempty(nn_i)
            nn_poses = zeros(3, length(nn_i));
            nn_points = cell(1, length(nn_i));
            for j = 1:length(nn_i)
                point_index = match_point_indexes(nn_i(j));
                nn_points{j} = mdl_points{point_index};
                nn_poses(:, j) = mdl_points{point_index}.pos;
            end
            pos3d = matches3d(:, i);
            distances3d = sum((nn_poses - repmat(pos3d, 1, length(nn_i))) .^ 2);
            nn_points = nn_points(distances3d < nei_thr_3d);
            nn_i = nn_i(distances3d < nei_thr_3d);
        end
        
        % Find co-visible points.
        if ~isempty(nn_i)
            cur_point_index = match_point_indexes(i);
            point = mdl_points{cur_point_index};
            is_covis = point.is_covisible_with(nn_points);
            nn_i = nn_i(is_covis);
        end
        adj_mat(i, nn_i) = 1;
    end
    
    adj_mat = adj_mat - eye(match_count) .* adj_mat; % Zero diagonal elemets.
end
