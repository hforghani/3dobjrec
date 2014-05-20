function [new_corr] = filter_corr(query_poses, points, correspondences, desc_model, points_array, query_im_name)

    image = imread(query_im_name);
    figure(1); imshow(image);
    colors = {'r','g','b','c','m','y','k','w'};
    
    % 2d local consistency
    adj_mat_2d = get_2d_cons_matrix(correspondences, query_poses);
    
    points_model_indexes = points(1,:);
    models_i = unique(points_model_indexes);
    model_count = length(models_i);
    result_corr_indexes = [];

    for i = 1 : model_count
        fprintf('validating hyp %d ... ', i);
        
        % Separate points and correspondences related to this model.
        model_i = models_i(i);
        is_of_model = points_model_indexes == model_i;
        model_indexes = find(is_of_model);
        model_points = points(:, is_of_model);
        model_corr_indexes = find(ismember(correspondences(2,:), model_indexes));
        model_corr = correspondences(:, model_corr_indexes);
        
%         adj_mat = hyp_cons_graph(correspondences, model_query_poses, model_points, model_point_indexes, points_array{model_i});
        % 3d local consistency
        adj_mat_3d = get_3d_cons_matrix(model_corr, model_points, points_array);

        % Calculate adjacency matrix of consistency graph then compute
        % confidence of each model hypothesis.
        adj_mat = adj_mat_2d(model_corr_indexes, model_corr_indexes) & adj_mat_3d;
        confidence = sum(sum(adj_mat));
        
        % Plot consistency graph of query poses
        figure(1); hold on;
        model_query_poses = query_poses(:, model_corr(1,:)); % May have repeated poses.
        gplot(adj_mat, model_query_poses', ['-o' colors{mod(i,length(colors))+1}]);
        fprintf('done, confidence = %d, ', confidence);
        
        % Filter hypotheses with low confidence, then filter
        % correspondences not present in 3-complete subgraphs.
        conf_thr = length(unique(model_corr(1,:))) / 3;
        if confidence > conf_thr
            adj_path_3 = adj_mat ^ 3;
            is_in_3complete = diag(adj_path_3) > 1;
            result_corr_indexes = [result_corr_indexes, model_corr_indexes(is_in_3complete)];
            scatter(model_query_poses(1, is_in_3complete), model_query_poses(2, is_in_3complete), 'filled', 'MarkerFaceColor', colors{mod(i,length(colors))+1});
            
            fprintf('accepted\n');
        else
            fprintf('rejected\n');
        end
    end

    new_corr = correspondences(:, result_corr_indexes);
end

function adj_mat = hyp_cons_graph(correspondences, query_poses, point_poses, point_indexes, mdl_points)
% Construct a graph which its nodes are correspondences and there is an 
% edge between each two consistent nodes.
    % 2d local consistency
    adj_mat_2d = get_2d_cons_matrix(correspondences, query_poses);
    
    % 3d local consistency
    adj_mat_3d = get_3d_cons_matrix(correspondences, point_poses, point_indexes, mdl_points);
    
    adj_mat = adj_mat_2d & adj_mat_3d;
end


function adj_mat = get_2d_cons_matrix(correspondences, query_poses)
    % Find 2d local consistent poses for each query pos.
    nei_thr_2d = 50 ^ 2;
    nei_num = 20;
    q_pos_count = size(query_poses, 2);
    kdtree = vl_kdtreebuild(double(query_poses));
    [nei2d_indexes, distances2d] = vl_kdtreequery(kdtree, query_poses, query_poses, 'NUMNEIGHBORS', nei_num);
    nei2d_indexes(distances2d > nei_thr_2d) = 0;
    nei2d_indexes(1, :) = [];
    
    % Construct graph of 2d local consistency.
    corr_count = size(correspondences, 2);
    adj_mat = zeros(corr_count);
    for i = 1:q_pos_count
        nn_i = nei2d_indexes(:, i);
        nn_i = nn_i(nn_i ~= 0);
        
        if ~isempty(nn_i)
            % Find correspondences related to neighbor poses.
            nn_i_corr_indexes = zeros(1, corr_count);
            for j = 1:length(nn_i)
                nn_i_corr_indexes = nn_i_corr_indexes | (correspondences(1,:) == nn_i(j));
            end
            % Set the related components of the matrix equal to one.
            adj_mat(correspondences(1,:) == i, nn_i_corr_indexes) = 1;
        end
    end
    adj_mat = adj_mat | adj_mat';
    adj_mat = adj_mat - eye(corr_count) .* adj_mat; % Zero diagonal elemets.
end

function adj_mat = get_3d_cons_matrix(correspondences, point_poses, point_indexes, mdl_points)
    nei_thr_3d = 1 ^ 2;
    nei_num = 20;
    points_count = size(point_poses,2);

    % Find spatially close points.
    kdtree = vl_kdtreebuild(double(point_poses));
    [nei_indexes, distances] = vl_kdtreequery(kdtree, point_poses, point_poses, 'NUMNEIGHBORS', nei_num);
    nei_indexes(distances > nei_thr_3d) = 0;
    nei_indexes(1, :) = [];
    
    % Construct graph of 3d local consistency.
    corr_count = size(correspondences, 2);
    adj_mat = false(corr_count);
    for i = 1:points_count
        nn_i = nei_indexes(:, i);
        nn_i = nn_i(nn_i ~= 0);
        if ~isempty(nn_i)
            % Find correspondences related to neighbor poses.
            nn_i_corr_indexes = zeros(1, corr_count);
            for j = 1:length(nn_i)
                nn_i_corr_indexes = nn_i_corr_indexes | (correspondences(2,:) == nn_i(j));
            end
            % Set the related components of the matrix equal to one.
            adj_mat(correspondences(2,:) == i, nn_i_corr_indexes) = 1;
        end
    end
    adj_mat = adj_mat | adj_mat';
    
    % Find co-visible points.
    points = cell(1, points_count);
    for i = 1:points_count
        points{i} = mdl_points{point_indexes(i)};
    end
    for i = 1:corr_count
        point = points{i};
        neighbors = adj_mat(i,:);
        cons_points = points(neighbors);
        is_covis = point.is_covisible_with(cons_points);
        adj_mat(i, neighbors) = adj_mat(i, neighbors) & is_covis;
    end

    adj_mat = adj_mat | adj_mat';
    adj_mat = adj_mat - eye(corr_count) .* adj_mat; % Zero diagonal elemets.
end
