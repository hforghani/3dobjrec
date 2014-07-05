function [sel_model_i, sel_corr, sel_adj_mat] = filter_corr(query_frames, points, correspondences, models, obj_names, query_im_name)

    addpath utils;
    
    global colors image;
    image = imread(query_im_name);
    colors = {'r','g','b','c','m','y','k','w'};
    
    % 2d local consistency
    query_poses = query_frames(1:2, :);
    adj_mat_2d = get_2d_cons_matrix(correspondences, query_frames);
    figure(1); imshow(image); hold on;
    gplot(adj_mat_2d, query_poses(:,correspondences(1,:))', '-.');
    
    % Create empty matrices.
    points_model_indexes = points(1,:);
    model_count = length(models);
    confidences = zeros(model_count, 1);
    adj_matrices = cell(model_count, 1);
    
%     figure(2); imshow(image);

    for i = 1 : model_count
        fprintf('validating hyp "%s" ... ', obj_names{i});
        
        % Separate points and correspondences related to this model.
        is_of_model = points_model_indexes == i;
        model_indexes = find(is_of_model);
        model_points = points(:, is_of_model);
        model_corr_indexes = find(ismember(correspondences(2,:), model_indexes));
        model_corr = correspondences(:, model_corr_indexes);
        model_corr(2,:) = reindex_arr(model_indexes, model_corr(2,:));
        
        % 3d local consistency
%         tic;
        pnt_adj_covis = covis_matrix(model_points, models{i}.points);
%         fprintf('3d covisibility check: %f\n', toc);
        adj_mat_3d = local_cons3d_matrix(model_corr, model_points, models{i}.points, pnt_adj_covis);

        % Show 3d local consistency graph of model points.
%         all_poses3d = models{i}.get_poses();
%         point_indexes = model_points(2, model_corr(2,:));
%         poses3d = all_poses3d(:, point_indexes);
%         figure; scatter3(all_poses3d(1,:), all_poses3d(2,:), all_poses3d(3,:), 5);
%         hold on; gplot3(adj_mat_3d, poses3d');
%         title(obj_names{i}, 'Interpreter', 'none');

        % Calculate adjacency matrix of consistency graph then compute
        % confidence of each model hypothesis.
        conf_adj_mat = adj_mat_2d(model_corr_indexes, model_corr_indexes) & adj_mat_3d;
        confidence = sum(sum(conf_adj_mat));
        confidences(i) = confidence;

        % Calculate final compatibility adjucency matrix.
        adj_mat = corr_comp_matrix(model_corr, query_frames, model_points, models{i}, conf_adj_mat, pnt_adj_covis);
        adj_matrices{i} = adj_mat;
        
        % Plot consistency graph of query poses
%         color = colors{mod(i,length(colors))+1};
%         model_query_poses = query_poses(:, model_corr(1,:)); % May have repeated poses.
%         figure(2); hold on;
%         gplot(adj_mat, model_query_poses', ['-o' color]);

        fprintf('done, confidence = %d\n', confidence);
    end
    
    % Choose top hypotheses, then filter correspondences not present in 
    % 3-complete subgraphs.
    N = min(5, model_count);
    [sel_model_i, sel_corr, sel_adj_mat] = choose_top_hyp(confidences, adj_matrices, N, points, query_poses, correspondences, obj_names);
end


function adj_mat = get_2d_cons_matrix(correspondences, query_frames)
    SCALE_BASED_NEI = 100;
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
        nn_i = nn_i(dist_i < SCALE_BASED_NEI * query_frames(3, correspondences(1,i)));
        adj_mat(i, nn_i) = 1;
    end
    
    % Make the matrix symmetric and with zero diagonal.
    adj_mat = adj_mat | adj_mat';
    adj_mat = adj_mat .* ~eye(corr_count);
end


function adj_mat = local_cons3d_matrix(correspondences, points, points_arr, covis_mat)
% Get adjucency matrix of 3d local consistency matrix of correspondences.
% correspondences: correspondences related to points of an object
% points: 2*P matrix of points of an abject; each column contains model
% index and point index
% points_arr: cell array of object points of type Point
    points_count = size(points,2);
    nei_num = floor(length(points_arr) * 0.05);

    % Put 3d point poses in a 3*P matrix.
    all_poses = zeros(3, length(points_arr));
    for i = 1:length(points_arr)
        all_poses(:,i) = points_arr{i}.pos;
    end
    point_poses = all_poses(:, points(2, :));

    % Find spatially close points.
    kdtree = vl_kdtreebuild(double(all_poses));
    [indexes, ~] = vl_kdtreequery(kdtree, all_poses, point_poses, 'NUMNEIGHBORS', nei_num + 1);
    indexes(1,:) = [];
    
    % Construct graph of 3d local consistency.
    pnt_adj_mat = false(points_count);
    for i = 1:points_count
        nn_i = indexes(:, i);
        [~, inn, ~] = intersect(nn_i, points(2, covis_mat(i, :)));
        sorted_inn = sort(inn);
        nei_indexes = nn_i(sorted_inn(1:min(nei_num, length(sorted_inn))));
        [~, ipoints, ~] = intersect(points(2,:), nei_indexes);
        pnt_adj_mat(i, ipoints) = 1;
    end
    
    % Make the matrix symmetric and with zero diagonal.
    pnt_adj_mat = pnt_adj_mat | pnt_adj_mat';
    pnt_adj_mat = pnt_adj_mat .* ~eye(points_count);

    % Construct correspondences 3d local consistency graph.
    corr_count = size(correspondences, 2);
    adj_mat = false(corr_count);
    for i = 1 : corr_count
        adj_mat(i, :) = pnt_adj_mat(correspondences(2,i), correspondences(2,:));
    end
end

function pnt_adj_mat = covis_matrix(points, points_arr)
% Get adjucency matrix of covisibility graph of correspondences. There is
% an edge between two nodes if their 3d points are covisible in any camera.
    points_count = size(points,2);

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
end

function adj_mat = corr_comp_matrix(correspondences, query_frames, points, model, cons_adj_mat, covis_adj_mat)
% correspondences :     2*C matrix
% query_frames :        4*Q matrix
% point :               2*P matrix
% model :               instance of Model
% cons_adj_mat :        C*C adjucency matrix of local consistence
% covis_adj_mat :       P*P adjucency matrix of covisibility
% adj_mat :             C*C adjucency matrix of general consistency
    corr_count = size(correspondences, 2);

    % Construct correspondences covisibility graph.
    cor_covis_adj_mat = false(corr_count);
    for i = 1 : corr_count
        cor_covis_adj_mat(i, :) = covis_adj_mat(correspondences(2,i), correspondences(2,:));
    end
    
    % Include correspondences of covisible points.
    adj_mat = cor_covis_adj_mat;
    
    % Remove filtered correspondences in the local filtering stage.
    retained_corr = any(cons_adj_mat, 1);
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
    f = model.calibration.fx; % Focal length
    image_coord_poses = [query_frames(1:2,correspondences(1, :));
                        ones(1,corr_count) * f];
    nonzero = sizes ~= 0;
    est_poses(:,nonzero) = repmat((sizes(nonzero) ./ scales(nonzero)), 3, 1) ...
                        .* image_coord_poses(:, nonzero);
    
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

function [sel_model_i, sel_corr, sel_adj_mat] = choose_top_hyp(confidences, adj_matrices, N, points, query_poses, correspondences, obj_names)
    % sel_model_i : N*1 matrix of selected model indexes
    % sel_corr : N*1 cell of selected correspondences which each element is
    % the 2*P matrix of correspondences
    % sel_adj_mat : N*1 cell of selected adjacent marices each one related 
    % to the corresponding element of sel_corr.
    global colors image;
    
    [~, sort_indexes] = sort(confidences, 'descend');
    sel_model_i = zeros(N,1);
    sel_corr = cell(N,1);
    sel_adj_mat = cell(N,1);

    for i = 1 : N
        % Find nodes in 3-complete subgraphs.
        model_i = sort_indexes(i);
        sel_model_i(i) = model_i;
        adj_mat = adj_matrices{model_i};
        adj_path_3 = adj_mat ^ 3;
        is_in_3complete = diag(adj_path_3) >= 2;
        
        % Separated correspondences related to top hypotheses.
        points_model_indexes = points(1,:);
        model_indexes = find(points_model_indexes == model_i);
        model_corr_indexes = find(ismember(correspondences(2,:), model_indexes));
        sel_corr{i} = correspondences(:, model_corr_indexes(is_in_3complete));
        adj_mat(~is_in_3complete, :) = [];
        adj_mat(:, ~is_in_3complete) = [];
        sel_adj_mat{i} = adj_mat;

        % Show compatibility graphs and nodes in 3-complete subgraphs.
        model_query_poses = query_poses(:, sel_corr{i}(1,:));
        color = colors{mod(model_i,length(colors))+1};
        figure(3); subplot(floor(sqrt(N)), ceil(sqrt(N)), i);
        imshow(image); hold on; 
        gplot(adj_mat, model_query_poses', ['-o' color]);
        title(obj_names{model_i}, 'Interpreter', 'none');
        fprintf('hyp ''%s'' chose (%s)\n', obj_names{model_i}, color);
    end
end
