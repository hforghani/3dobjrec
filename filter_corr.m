function [sel_model_i, sel_corr, sel_adj_mat] = filter_corr(q_frames, points, corr, corr_dist, models, obj_names, q_im_name)

    global colors image;
    image = imread(q_im_name);
    colors = {'r','g','b','c','m','y','k','w'};
    
    SCALE_FACTOR = 150;
    NEI3D_RATIO = 0.1;
    N = 7;
    
    % 2d local consistency
    cons2d = consistency2d(corr, q_frames, SCALE_FACTOR);
    q_poses = q_frames(1:2, :);
    figure; imshow(image); hold on;
    gplot(cons2d, q_poses(:,corr(1,:))', '-.');
    
    % Create empty matrices.
    model_count = length(models);
    confidences = zeros(model_count, 1);
    local_cons_arr = cell(model_count, 1);
    
    for i = 1 : model_count
        fprintf('validating hyp "%s" ... ', obj_names{i});
        
        % Separate points and correspondences related to this model.
        [model_points, model_corr, model_cons2d, ~] = separate_hyp_data(i, points, corr, cons2d);
        
        % 3d local consistency
        pnt_adj_covis = cons_covis3d(model_points, models{i}.points, model_corr, model_cons2d);
        adj_mat_3d = consistency3d(model_corr, model_points, models{i}.points, pnt_adj_covis, NEI3D_RATIO);

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
    
    % Write confidences to output file.
    [~, si] = sort(confidences, 'descend');
    fid = fopen('result/conf/conf.txt', 'w');
    for i = 1:model_count
        fprintf(fid, '%s\t%d\n', obj_names{si(i)}, confidences(si(i)));
    end
    fclose(fid);
    
    % Choose top hypotheses.
    [sel_model_i, sel_corr, sel_adj_mat] = choose_top_hyp(confidences, N, local_cons_arr, points, q_frames, corr, models, obj_names);
    
end


function adj_mat = corr_comp_matrix(model_corr, q_frames, model_points, model, local_cons)
% correspondences :     2*C matrix
% query_frames :        4*Q matrix
% point :               2*P matrix
% model :               instance of Model
% local_cons :          C*C adjucency matrix of local consistency
% adj_mat :             C*C adjucency matrix of general consistency
    corr_count = size(model_corr, 2);

    % Include correspondences of covisible points.
    adj_mat = true(corr_count);
    
    % Remove filtered correspondences in the local filtering stage.
    retained_corr = any(local_cons, 1);
    adj_mat(~retained_corr, :) = 0;
    adj_mat(:, ~retained_corr) = 0;
    
    % Remove correspondences with same query pose or 3d point.
    for i = 1:corr_count
        same_q_pos = model_corr(1,:) == model_corr(1,i);
        same_p_pos = model_corr(2,:) == model_corr(2,i);
        adj_mat(i, same_q_pos | same_p_pos) = 0;
    end
    adj_mat = adj_mat & adj_mat';

    % Add pairwise geometric check.
    MIN_TOLER = 0.8;
    MAX_TOLER = 1.25;
    adj_mat = pairwise_geo_check(model_corr, model_points, q_frames, model, adj_mat, MIN_TOLER, MAX_TOLER);

    % Add covisibility check.
    covis_adj_mat = cons_covis3d(model_points, model.points, model_corr, adj_mat);
    for i = 1 : corr_count
        adj_mat(i, :) = adj_mat(i, :) & covis_adj_mat(model_corr(2,i), model_corr(2,:));
    end

end

function adj_mat = pairwise_geo_check(model_corr, model_points, q_frames, model, adj_mat, min_toler, max_toler)
% adj_mat:      Add pairwise geometric check to initial adjucency matrix.
    
    % Estimate pose of points in the query camera.
    corr_count = size(model_corr, 2);
    point_poses = model.get_poses();
    point_poses = point_poses(:, model_points(2, model_corr(2, :)));
    sizes = model.point_sizes(model_points(2, model_corr(2, :)));
    scales = q_frames(3, model_corr(1, :));
    est_poses = zeros(3, corr_count);
    f = model.calibration.fx; % Focal length
    image_coord_poses = [q_frames(1:2,model_corr(1, :));
                        ones(1,corr_count) * f];
    nonzero = sizes ~= 0;
    est_poses(:,nonzero) = repmat((sizes(nonzero) ./ scales(nonzero)), 3, 1) ...
                        .* image_coord_poses(:, nonzero);
    
    % Check tolerance interval.
    for i = 1 : corr_count-1
        for j = i+1 : corr_count
            if adj_mat(i,j) && any(est_poses(:,i) ~= 0) && any(est_poses(:,j) ~= 0)
                geo_comp = norm(est_poses(:,i) - est_poses(:,j)) / norm(point_poses(:,i) - point_poses(:,j));
                if (geo_comp < min_toler || geo_comp > max_toler)
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
    
    fig_h = figure;

    for i = 1 : N
        hyp_i = sort_indexes(i);

        % Separate data related to the hypothesis.
        [model_points, model_corr, ~, ~] = separate_hyp_data(hyp_i, points, corr);
        local_cons = local_cons_arr{hyp_i};

        % Calculate final compatibility adjucency matrix.
        adj_mat = corr_comp_matrix(model_corr, q_frames, model_points, models{hyp_i}, local_cons);
        
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
        color = colors{mod(i,length(colors))+1};
        figure(fig_h); subplot(ceil(sqrt(N)), ceil(sqrt(N)), i);
        imshow(image); hold on; 
        gplot(adj_mat, model_query_poses', ['-o' color]);
        title(obj_names{hyp_i}, 'Interpreter', 'none');
        fprintf('hyp ''%s'' chose (%s)\n', obj_names{hyp_i}, color);
    end
end
