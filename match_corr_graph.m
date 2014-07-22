function [sel_model_i, sel_corr, sel_adj_mat] = match_corr_graph(q_frames, points, corr, corr_dist, models, obj_names, q_im_name)

%     global colors image;
    image = imread(q_im_name);
    colors = {'r','g','b','c','m','y','k','w'};
    
    SCALE_FACTOR = 8;
    NEI3D_RATIO = 0.05;
    N = 7;
    
%     figure; imshow(image); hold on; scatter(q_frames(1,:),q_frames(2,:), 20, 'r', 'filled');
    
    % 2d local consistency
    cons2d = consistency2d(corr, q_frames, points, SCALE_FACTOR);
%     q_poses = q_frames(1:2, :);
%     figure; imshow(image); hold on;
%     gplot(cons2d, q_poses(:,corr(1,:))', '-.');
    
    model_count = length(models);
    qcount = size(q_frames,2);    
    confidences = zeros(model_count, 1);
    retained_corr = cell(model_count, 1);
    
%     conf_fig = figure;
%     subplotx = floor(sqrt(model_count));
%     subploty = ceil(model_count/subplotx);

    for i = 1 : model_count
        fprintf('validating hyp "%s" graph ... \n', obj_names{i});
        
        % Separate data related to the hypothesis.
        [model_points, model_corr, model_cons2d, model_corr_dist] = separate_hyp_data(i, points, corr, cons2d, corr_dist);
        pcount = size(model_points, 2);
        
        %%%% Compute confidence by Q.Hao paper method.

%         % 3d local consistency
%         pnt_adj_covis = cons_covis3d(model_points, models{i}.points, model_corr, model_cons2d);
%         cons3d = consistency3d(model_corr, model_points, models{i}.points, pnt_adj_covis, NEI3D_RATIO);
%         
%         % Calculate hypothesis confidence.
%         local_cons = model_cons2d & cons3d;
%         conf = sum(sum(local_cons));
%         confidences(i) = conf;
%         matched_corr_i = any(local_cons, 1);
%         adj_mat = local_cons;
%         retained_corr{i} = matched_corr_i;

        %%%% Compute confidence by graph matching.
        
        % by spectral matching
        if strcmp(obj_names{i}, 'box_turtle')
            0;
        end
        [sol, score, W] = graph_matching_spectral(model_corr, model_corr_dist, q_frames, model_points, models{i}, true);
        nondiag = W(~logical(eye(size(W))));
        figure; hist(nondiag(nondiag > 10^-4), 20); title(obj_names{i}, 'Interpreter', 'none');
        
        sol = logical(sol);
%         confidences(i) = sum(matched_corr_i);
        confidences(i) = score;
        retained_corr{i} = sol;
        adj_mat = W > 0.7;
        
        % Plot matched correspondences.
        color = colors{mod(i,length(colors))+1};
        q_poses = q_frames(1:2, model_corr(1,:));
        matched_q_poses = q_frames(1:2, model_corr(1, sol));
        figure;
%         subplot(1,2,1);
        imshow(image); hold on;
        scatter(q_poses(1,:), q_poses(2,:), ['o' color]);
        gplot(adj_mat, q_poses', ['-o' color]);
        scatter(matched_q_poses(1,:), matched_q_poses(2,:), ['o' color], 'filled');
        for j = 1:size(q_poses,2)
            text(q_poses(1,j), q_poses(2,j), num2str(j), 'Color', 'r');
        end
        title(obj_names{i}, 'Interpreter', 'none');

        fprintf('confidence = %f\n', confidences(i));
    end
    
    % Choose top hypotheses.
    [~, sort_indexes] = sort(confidences, 'descend');
    N = min(N, length(confidences));
    top_indexes = sort_indexes(1:N);
    fprintf('===== %d top hypotheses chose\n', N);

    sel_model_i = zeros(N, 1);
    sel_corr = cell(N, 1);
    sel_adj_mat = cell(N, 1);
%     
%     matrix_fig = figure;
%     points_fig = figure;
%     subplotx = floor(sqrt(N));
%     subploty = ceil(N/subplotx);
    
    for i = 1 : length(top_indexes)
        hyp_i = top_indexes(i);
        fprintf('=== matching graph of %s ===\n', obj_names{hyp_i});
        
%         figure(matrix_fig); subplot(subplotx,subploty,i);

        % Separate data related to the hypothesis.
        [model_points, model_corr, ~, model_corr_dist] = separate_hyp_data(hyp_i, points, corr, cons2d, corr_dist);
        pcount = size(model_points, 2);
        retained = retained_corr{hyp_i};
        ret_corr = model_corr(:,retained);
        ret_corr_dist = model_corr_dist(retained);

        [sol, score, W] = graph_matching_spectral(ret_corr, ret_corr_dist, q_frames, model_points, models{hyp_i}, false);
        sol = logical(sol);
        adj_mat = W(sol, sol) > 0.9;
        fprintf('number of final matches: %d\n', nnz(sol));

%         title(obj_names{hyp_i}, 'Interpreter', 'none');

        sel_model_i(i) = hyp_i;
        points_model_indexes = points(1,:);
        model_indexes = find(points_model_indexes == hyp_i);
        model_corr_indexes = ismember(corr(2,:), model_indexes);
        sel_corr{i} = corr(:, model_corr_indexes);
        ret_indexes = find(retained);
        sel_corr{i} = sel_corr{i}(:, ret_indexes(sol));
        sel_adj_mat{i} = adj_mat;

        % Plot matched correspondences.
%         color = colors{mod(hyp_i,length(colors))+1};
%         q_poses = q_frames(1:2, ret_corr(1,:));
%         matched_q_poses = q_frames(1:2, ret_corr(1, sol));
%         figure;
% %         subplot(1,2,1);
%         imshow(image); hold on;
%         gplot(W > 0.9, q_poses', ['-o' color]);
%         scatter(matched_q_poses(1,:), matched_q_poses(2,:), ['o' color], 'filled');
%         title(['pairwise geometric compatibility: ' obj_names{hyp_i}], 'Interpreter', 'none');
    end
    
end


function [sol, score, W] = graph_matching_spectral(model_corr, model_corr_dist, q_frames, model_points, model, is_local, interactive)
    if nargin == 6
        interactive = false;
    end

    [W, sol0] = affinity_matrix(model_corr, model_corr_dist, q_frames, model_points, model, is_local);
    
    if interactive
        spy(W);
    end

    % Create initial solution.
    ccount = size(model_corr, 2);
%     sol0 = ones(ccount,1);
%     sol0 = sol0/norm(sol0);
%     sol0 = zeros(ccount,1);
    
    % Spectral graph matching
%     fprintf('running spectral matching ... ');
%     [sol, stats_ipfp]  = spectral_matching_ipfp(W, model_corr(1,:), model_corr(2,:));
%     score = stats_ipfp.best_score;

%     D = -ones(ccount,1);
%     D = zeros(ccount,1);
%     [sol, x_opt, scores, score]  = ipfp(W, D, sol0, model_corr(1,:), model_corr(2,:), 50);

    [sol, stats_ipfp]  = ipfp_gm(W, sol0, model_corr(1,:), model_corr(2,:));
    score = stats_ipfp.best_score;
%     fprintf('done\n');

end


function [W, sol0] = affinity_matrix(model_corr, model_corr_dist, q_frames, model_points, model, is_local)
    ccount = size(model_corr,2);
    
    %%%%%% Compute different consistency measures.
    
    if is_local
%         fprintf('computing 2d local consistency ... ');
        [adj2d, nei_score2d] = consistency2d(model_corr, q_frames, model_points, 8);
%         fprintf('done\n');
%         fprintf('computing 3d covisibility ... ');
        cons_covis = cons_covis3d(model_points, model.points, model_corr, ones(ccount));
%         fprintf('done\n');
%         fprintf('computing 3d local consistency ... ');
        [adj3d, nei_score3d] = consistency3d(model_corr, model_points, model.points, cons_covis, 0.05);
%         fprintf('done\n');
    else
%         fprintf('computing pairwise geometric consistency ... ');
        [adj_geo, geo_score] = cons_pairwise_geo(model_corr, model_points, q_frames, model, ones(ccount), 0.8, 1.25);
%         fprintf('done\n');
    end

    %%%%%% Create affinity matrix W.
%     fprintf('computing correspondences consistency matrix ... ');
    % Set non-diagonal elements of affinity matrix (affinity between two correspondences).
    if is_local
        W = sqrt(nei_score2d .* nei_score3d);
        sol0 = double(any(adj2d & adj3d, 2));
    else
        W = geo_score;
        sol0 = double(any(adj_geo, 2));
    end
    % Normalize to [0,1].
    if max(W(:)) - min(W(:)) ~= 0
        W = (W - min(W(:))) / (max(W(:)) - min(W(:)));
    end

%     sol0 = double(any(W > 0.7, 2));

    % Set diagonal elements of affinity matrix.
%     d = 1 ./ (model_corr_dist + 1);
%     % Normalize to [0,1].
%     W(logical(eye(ccount))) = (d - min(d)) / (max(d) - min(d));
    W(logical(eye(ccount))) = 0;
    
    W = sparse(W);
%     fprintf('done\n');
end
