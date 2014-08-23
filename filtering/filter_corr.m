function [sel_model_i, sel_corr, sel_adj_mat] = filter_corr(q_frames, points, corr, models, obj_names, q_im_name, options, interactive)

    if nargin < 8
        interactive = 0;
    end
    
    global colors image;
    image = imread(q_im_name);
    colors = {'r','g','b','c','m','y','k','w'};
        
    % 2d local consistency
    cons2d = consistency2d(corr, q_frames, points, options);
    if interactive > 1
        q_poses = q_frames(1:2, :);
        figure; imshow(image); hold on;
        gplot(cons2d, q_poses(:,corr(1,:))', '-.');
    end
    
    % Create empty matrices.
    model_count = length(models);
    confidences = zeros(model_count, 1);
    local_cons_arr = cell(model_count, 1);
    
    for i = 1 : model_count
        if interactive; fprintf('validating hyp "%s" ... ', obj_names{i}); end
        
        % Separate points and correspondences related to this model.
        [model_points, model_corr, model_cons2d, ~] = separate_hyp_data(i, points, corr, cons2d);
        
        % 3d local consistency
        pnt_adj_covis = cons_covis3d(model_points, models{i}.points, model_corr, model_cons2d);
        adj_mat_3d = consistency3d(model_corr, model_points, models{i}.points, pnt_adj_covis, options);

        % Calculate adjacency matrix of consistency graph then compute
        % confidence of each model hypothesis.
        local_cons = model_cons2d & adj_mat_3d;
        conf = sum(sum(local_cons));
        confidences(i) = conf;
        local_cons_arr{i} = local_cons;

        if interactive > 1
            % Show 3d local consistency graph of model points.
%             all_poses3d = models{i}.get_poses();
%             point_indexes = model_points(2, model_corr(2,:));
%             poses3d = all_poses3d(:, point_indexes);
%             figure; scatter3(all_poses3d(1,:), all_poses3d(2,:), all_poses3d(3,:), 5);
%             hold on; gplot3(adj_mat_3d, poses3d');
%             title(obj_names{i}, 'Interpreter', 'none');

            color = colors{mod(i,length(colors))+1};
            q_poses = q_frames(1:2, model_corr(1,:));
            retained_q_poses = q_frames(1:2, model_corr(1, any(local_cons)));
            figure; imshow(image); hold on;
            scatter(q_poses(1,:), q_poses(2,:), ['o' color]);
            gplot(local_cons, q_poses', ['-o' color]);
            scatter(retained_q_poses(1,:), retained_q_poses(2,:), ['o' color], 'filled');
            for j = 1:size(q_poses,2)
                text(q_poses(1,j), q_poses(2,j), num2str(j), 'Color', 'r');
            end
            title(obj_names{i}, 'Interpreter', 'none');
        end
        
        if interactive; fprintf('done, confidence = %d\n', conf); end
    end
    
%     % Write confidences to output file.
%     [~, si] = sort(confidences, 'descend');
%     fid = fopen('result/conf/conf.txt', 'w');
%     for i = 1:model_count
%         if interactive; fprintf(fid, '%s\t%d\n', obj_names{si(i)}, confidences(si(i))); end
%     end
%     fclose(fid);
    
    % Choose top hypotheses.
    [sel_model_i, sel_corr, sel_adj_mat] = choose_top_hyp(confidences, options.top_hyp_num, local_cons_arr, points, q_frames, corr, models, obj_names, interactive);
    
end


function [sel_model_i, sel_corr, sel_adj_mat] = choose_top_hyp(confidences, N, local_cons_arr, points, q_frames, corr, models, obj_names, interactive)
    % sel_model_i : N*1 matrix of selected model indexes
    % sel_corr : N*1 cell of selected correspondences which each element is
    % the 2*P matrix of correspondences
    % sel_adj_mat : N*1 cell of selected adjacent marices each one related 
    % to the corresponding element of sel_corr.
    
    if nargin < 9
        interactive = false;
    end
    
    global colors image;
    
    [~, sort_indexes] = sort(confidences, 'descend');
    N = min(N, length(confidences));
    if interactive; fprintf('===== %d top hypotheses chose\n', N); end
    
    sel_model_i = zeros(N,1);
    sel_corr = cell(N,1);
    sel_adj_mat = cell(N,1);
    
    if interactive > 1; fig_h = figure; end

    for i = 1 : N
        hyp_i = sort_indexes(i);

        % Separate data related to the hypothesis.
        [model_points, model_corr, ~, ~] = separate_hyp_data(hyp_i, points, corr);
        local_cons = local_cons_arr{hyp_i};

        % Calculate final compatibility adjucency matrix.
        adj_mat = cons_global(model_corr, q_frames, model_points, models{hyp_i}, local_cons);
        
        % Retain correspondences on 3-complete subgraphs.
        points_model_indexes = points(1,:);
        model_indexes = find(points_model_indexes == hyp_i);
        model_corr_indexes = ismember(corr(2,:), model_indexes);
        sel_model_i(i) = hyp_i;
        sel_corr{i} = corr(:, model_corr_indexes);
        sel_adj_mat{i} = adj_mat;

        % Show compatibility graphs and nodes in 3-complete subgraphs.
        if interactive > 1
            model_query_poses = q_frames(1:2, sel_corr{i}(1,:));
            color = colors{mod(i,length(colors))+1};
            figure(fig_h); subplot(ceil(sqrt(N)), ceil(sqrt(N)), i);
            imshow(image); hold on; 
            gplot(adj_mat, model_query_poses', ['-o' color]);
            title(obj_names{hyp_i}, 'Interpreter', 'none');
        end
        
        if interactive; fprintf('hyp ''%s'' chose\n', obj_names{hyp_i}); end
    end
end
