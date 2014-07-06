function [sel_model_i, sel_corr, sel_adj_mat] = filter_corr(q_frames, points, corr, corr_dist, models, obj_names, q_im_name)

    global colors image;
    image = imread(q_im_name);
    colors = {'r','g','b','c','m','y','k','w'};
    
    % 2d local consistency
    cons2d = consistency2d(corr, q_frames, 100);
    q_poses = q_frames(1:2, :);
%     figure(1); imshow(image); hold on;
%     gplot(adj_mat_2d, q_poses(:,corr(1,:))', '-.');
    
    % Create empty matrices.
    model_count = length(models);
    confidences = zeros(model_count, 1);
    local_cons_arr = cell(model_count, 1);
    
%     figure(2); imshow(image);

    for i = 1 : model_count
        fprintf('validating hyp "%s" ... ', obj_names{i});
        
        % Separate points and correspondences related to this model.
        [model_points, model_corr, model_cons2d, ~] = separate_hyp_data(i, points, corr, cons2d);
        
        % 3d local consistency
%         tic;
        pnt_adj_covis = cons_covis3d(model_points, models{i}.points, model_corr, model_cons2d);
%         fprintf('3d covisibility check: %f\n', toc);
        adj_mat_3d = consistency3d(model_corr, model_points, models{i}.points, pnt_adj_covis);

        % Show 3d local consistency graph of model points.
%         all_poses3d = models{i}.get_poses();
%         point_indexes = model_points(2, model_corr(2,:));
%         poses3d = all_poses3d(:, point_indexes);
%         figure; scatter3(all_poses3d(1,:), all_poses3d(2,:), all_poses3d(3,:), 5);
%         hold on; gplot3(adj_mat_3d, poses3d');
%         title(obj_names{i}, 'Interpreter', 'none');

        % Calculate adjacency matrix of consistency graph then compute
        % confidence of each model hypothesis.
        local_cons = model_cons2d & adj_mat_3d;
        conf = sum(sum(local_cons));
        confidences(i) = conf;
        local_cons_arr{i} = local_cons;

        fprintf('done, confidence = %d\n', conf);
    end
    
    % Choose top hypotheses.
    N = 5;
    [sel_model_i, sel_corr, sel_adj_mat] = choose_top_hyp(confidences, N, local_cons_arr, points, q_frames, corr, models, obj_names);
    
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

function [sel_model_i, sel_corr, sel_adj_mat] = choose_top_hyp(confidences, N, local_cons_arr, points, q_frames, corr, models, obj_names)
    % sel_model_i : N*1 matrix of selected model indexes
    % sel_corr : N*1 cell of selected correspondences which each element is
    % the 2*P matrix of correspondences
    % sel_adj_mat : N*1 cell of selected adjacent marices each one related 
    % to the corresponding element of sel_corr.
    global colors image;
    
    [~, sort_indexes] = sort(confidences, 'descend');
    N = min(N, length(confidences));
    fprintf('===== %d top hypotheses chose\n', N);
    
    sel_model_i = zeros(N,1);
    sel_corr = cell(N,1);
    sel_adj_mat = cell(N,1);

    for i = 1 : N
        hyp_i = sort_indexes(i);

        % Separate data related to the hypothesis.
        [model_points, model_corr, ~, ~] = separate_hyp_data(hyp_i, points, corr);
        local_cons = local_cons_arr{hyp_i};

        % Calculate final compatibility adjucency matrix.
        pnt_adj_covis = cons_covis3d(model_points, models{hyp_i}.points);
        adj_mat = corr_comp_matrix(model_corr, q_frames, model_points, models{hyp_i}, local_cons, pnt_adj_covis);
        
        % Find nodes in 3-complete subgraphs.
        adj_path_3 = adj_mat ^ 3;
        is_in_3complete = diag(adj_path_3) >= 2;
        adj_mat(~is_in_3complete, :) = [];
        adj_mat(:, ~is_in_3complete) = [];
        
        % Retain correspondences on 3-complete subgraphs.
        points_model_indexes = points(1,:);
        model_indexes = find(points_model_indexes == hyp_i);
        model_corr_indexes = find(ismember(corr(2,:), model_indexes));
        sel_model_i(i) = hyp_i;
        sel_corr{i} = corr(:, model_corr_indexes(is_in_3complete));
        sel_adj_mat{i} = adj_mat;

        % Show compatibility graphs and nodes in 3-complete subgraphs.
        model_query_poses = q_frames(1:2, sel_corr{i}(1,:));
        color = colors{mod(hyp_i,length(colors))+1};
        figure(3); subplot(floor(sqrt(N)), ceil(sqrt(N)), i);
        imshow(image); hold on; 
        gplot(adj_mat, model_query_poses', ['-o' color]);
        title(obj_names{hyp_i}, 'Interpreter', 'none');
        fprintf('hyp ''%s'' chose (%s)\n', obj_names{hyp_i}, color);
    end
end
