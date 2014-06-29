function new_corr = filter_corr(query_frames, points, correspondences, models, obj_names, query_im_name)

    addpath utils;
    
    image = imread(query_im_name);
    figure(1); imshow(image);
    global colors;
    colors = {'r','g','b','c','m','y','k','w'};
    
    % 2d local consistency
    query_poses = query_frames(1:2, :);
    adj_mat_2d = get_2d_cons_matrix(correspondences, query_frames);
    figure(5); imshow(image); hold on;
    gplot(adj_mat_2d, query_poses(:,correspondences(1,:))', '-.');
    
    % Create empty matrices.
    points_model_indexes = points(1,:);
    models_i = unique(points_model_indexes);
    model_count = length(models_i);
    confidences = zeros(max(models_i), 1);
    adj_matrices = cell(max(models_i), 1);

    for i = 1 : model_count
        fprintf('validating hyp "%s" ... ', obj_names{i});
        
        % Separate points and correspondences related to this model.
        model_i = models_i(i);
        is_of_model = points_model_indexes == model_i;
        model_indexes = find(is_of_model);
        model_points = points(:, is_of_model);
        model_corr_indexes = find(ismember(correspondences(2,:), model_indexes));
        model_corr = correspondences(:, model_corr_indexes);
        model_corr(2,:) = reindex_arr(model_indexes, model_corr(2,:));
        
        % 3d local consistency
%         tic;
        adj_3d_close = corr_close_matrix(model_corr, model_points, models{model_i}.points);
        adj_3d_covis = corr_covis_matrix(model_corr, model_points, models{model_i}.points);
        adj_mat_3d = adj_3d_close & adj_3d_covis;
%         fprintf('3d local consistency: %f\n', toc);

        % Calculate adjacency matrix of consistency graph then compute
        % confidence of each model hypothesis.
        conf_adj_mat = adj_mat_2d(model_corr_indexes, model_corr_indexes) & adj_mat_3d;
        confidence = sum(sum(conf_adj_mat));
        confidences(model_i) = confidence;

        % Calculate final compatibility adjucency matrix.
        adj_mat = corr_comp_matrix(model_corr, query_frames, model_points, models{model_i}, conf_adj_mat, adj_3d_covis);
        adj_matrices{model_i} = adj_mat;
        
        % Plot consistency graph of query poses
%         color = colors{mod(model_i,length(colors))+1};
%         figure(1); hold on;
%         model_query_poses = query_poses(:, model_corr(1,:)); % May have repeated poses.
%         gplot(adj_mat, model_query_poses', ['-o' color]);
        fprintf('done, confidence = %d\n', confidence);
    end
    
    % Choose top hypotheses, then filter correspondences not present in 
    % 3-complete subgraphs.
    N = min(10, model_count);
    new_corr = choose_top_hyp(confidences, adj_matrices, N, points, query_poses, correspondences, obj_names);
end


function adj_mat = get_2d_cons_matrix(correspondences, query_frames)
    query_poses = query_frames(1:2, :);
    corr_count = size(correspondences, 2);

    % Find nearest neighbors for each query pose.
    corr_poses = query_poses(:, correspondences(1,:));
    nei_num = max(floor(corr_count / 10) , 2);
    kdtree = vl_kdtreebuild(double(corr_poses));
    [nei_indexes, distances] = vl_kdtreequery(kdtree, corr_poses, corr_poses, 'NUMNEIGHBORS', nei_num);
    
    % Construct graph of 2d local consistency.
    adj_mat = false(corr_count);
    for i = 1:corr_count
        nn_i = nei_indexes(:, i);
        dist_i = distances(:, i);
        % Check neighborhood distance.
        nn_i = nn_i(dist_i < 150 * query_frames(3, correspondences(1,i)));
        adj_mat(i, nn_i) = 1;
    end
    
    % Make the matrix symmetric and with zero diagonal.
    adj_mat = adj_mat | adj_mat';
    adj_mat = adj_mat .* ~eye(corr_count);
end


function adj_mat = corr_close_matrix(correspondences, points, points_arr)
% Get adjucency matrix of 3d closeness matrix of correspondences.
% correspondences: correspondences related to points of an object
% points: 2*P matrix of points of an abject; each column contains model
% index and point index
% model_points: cell array of object points of type Point
    nei_thr_3d = 0.7 ^ 2;
    points_count = size(points,2);
    nei_num = max(points_count / 2 , 2);

    % Put 3d point poses in a 3*P matrix.
    point_poses = zeros(3, points_count);
    for i = 1:points_count
        point_poses(:,i) = points_arr{points(2,i)}.pos;
    end
    corr_poses = point_poses(:, correspondences(2,:));

    % Find spatially close points.
    kdtree = vl_kdtreebuild(double(corr_poses));
    [nei_indexes, distances] = vl_kdtreequery(kdtree, corr_poses, corr_poses, 'NUMNEIGHBORS', nei_num);
    nei_indexes(distances > nei_thr_3d) = 0;
    
    % Construct graph of 3d local consistency.
    corr_count = size(correspondences, 2);
    adj_mat = false(corr_count);
    for i = 1:corr_count
        nn_i = nei_indexes(:, i);
        dist_i = distances(:, i);
        % Check neighborhood distance.
        nn_i = nn_i(dist_i < nei_thr_3d);
        adj_mat(i, nn_i) = 1;
    end
    
    % Make the matrix symmetric and with zero diagonal.
    adj_mat = adj_mat | adj_mat';
    adj_mat = adj_mat .* ~eye(corr_count);
end

function adj_mat = corr_covis_matrix(correspondences, points, points_arr)
% Get adjucency matrix of covisibility graph of correspondences. There is
% an edge between two nodes if their 3d points are covisible in any camera.
    points_count = size(points,2);
    corr_count = size(correspondences, 2);

    % Put 3d point poses in a 3*P matrix.
    point_instances = cell(1, points_count);
    for i = 1:points_count
        point_instances{i} = points_arr{points(2,i)};
    end
    
    % Find camera indexes in which each point is visible.
    cam_indexes = cell(points_count, 1);
    for i = 1:points_count
        cam_indexes{i} = point_instances{i}.cameras_visible_in();
    end
    
    % Construct points covisibility graph.
    pnt_adj_mat = false(points_count);
    for i = 1 : points_count - 1
        for j = i+1 : points_count
            pnt_adj_mat(i, j) = ~isempty(intersect(cam_indexes{i}, cam_indexes{j}));
        end
    end
    pnt_adj_mat = pnt_adj_mat | pnt_adj_mat';
    
    % Construct correspondences covisibility graph.
    adj_mat = false(corr_count);
    for i = 1 : corr_count
        adj_mat(i, :) = pnt_adj_mat(correspondences(2,i), correspondences(2,:));
    end
end

function adj_mat = corr_comp_matrix(correspondences, query_frames, points, model, conf_adj_mat, covis_adj_mat)
    corr_count = size(correspondences, 2);

    % Include correspondences of covisible points.
    adj_mat = covis_adj_mat;
    
    % Remove filtered correspondences in the local filtering stage.
    retained_corr = any(conf_adj_mat, 1);
    adj_mat(~retained_corr, :) = 0;
    adj_mat(:, ~retained_corr) = 0;
    
    % Remove correspondences with same query pose or 3d point.
    for i = 1:corr_count
        same_q_pos = correspondences(1,:) == correspondences(1,i);
        same_p_pos = correspondences(2,:) == correspondences(2,i);
        adj_mat(i, same_q_pos | same_p_pos) = 0;
    end
    adj_mat = adj_mat & adj_mat';
    
    % Estimate pose of points in the query camera.
    point_poses = model.get_poses();
    point_poses = point_poses(:, points(2, correspondences(2, :)));
    sizes = model.point_sizes(points(2, correspondences(2, :)));
    scales = query_frames(3, correspondences(1, :));
    est_poses = zeros(3, corr_count);
    nonzero = sizes ~= 0;
    sizes = sizes(nonzero);
    scales = scales(nonzero);
    coef = sizes ./ scales;
    for i = 1:3
        est_poses(i,nonzero) = coef .* point_poses(i,nonzero);
    end
    
    % Check tolerance interval.
    TOLER1 = 0.8;
    TOLER2 = 1.25;
    for i = 1 : corr_count-1
        for j = i+1 : corr_count
            if adj_mat(i,j) && any(est_poses(:,i) ~= 0) && any(est_poses(:,j) ~= 0)
                geo_comp = norm(est_poses(:,i) - est_poses(:,j)) / norm(point_poses(:,i) - point_poses(:,j));
                if (geo_comp < TOLER1 || geo_comp > TOLER2)
                    adj_mat(i,j) = 0;
                end
            end
        end
    end
    adj_mat = adj_mat & adj_mat';
end

function new_corr = choose_top_hyp(confidences, adj_matrices, N, points, query_poses, correspondences, obj_names)
    [~, sort_indexes] = sort(confidences, 'descend');
    result_corr_indexes = [];
    global colors;
    
    for i = 1 : N
        model_i = sort_indexes(i);
        adj_mat = adj_matrices{model_i};
        adj_path_3 = adj_mat ^ 3;
        is_in_3complete = diag(adj_path_3) >= 2;
        
        points_model_indexes = points(1,:);
        model_indexes = find(points_model_indexes == model_i);
        model_corr_indexes = find(ismember(correspondences(2,:), model_indexes));
        result_corr_indexes = [result_corr_indexes, model_corr_indexes(is_in_3complete)];

        model_corr = correspondences(:, model_corr_indexes);
        model_query_poses = query_poses(:, model_corr(1,:));
        color = colors{mod(model_i,length(colors))+1};
        figure(1); hold on;
        gplot(adj_mat, model_query_poses', ['-o' color]);
        scatter(model_query_poses(1, is_in_3complete), model_query_poses(2, is_in_3complete), 'filled', 'MarkerFaceColor', color);
        fprintf('hyp ''%s'' chose (%s)\n', obj_names{model_i}, color);
    end
    new_corr = correspondences(:, result_corr_indexes);
end
