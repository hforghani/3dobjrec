function [sel_model_i, sel_corr, sel_adj_mat] = match_corr_graph(q_frames, points, corr, corr_dist, models, obj_names, q_im_name, interactive)

    if nargin < 7
        interactive = false;
    end
    
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

        % Compute confidence by graph matching.
        [sol, score, W] = graph_matching(model_corr, model_corr_dist, q_frames, model_points, models{i}, 'IsLocal', true, 'Method', 'gradient');
        sol = logical(sol);
%         confidences(i) = sum(matched_corr_i);
        confidences(i) = score;
        retained_corr{i} = sol;

        % Plot histogram of W values.
%         nondiag = W(~logical(eye(size(W))));
%         figure; hist(nondiag(nondiag > 10^-4), 20); title(obj_names{i}, 'Interpreter', 'none');
        
        % Plot matched correspondences.
        if interactive
            color = colors{mod(i,length(colors))+1};
            q_poses = q_frames(1:2, model_corr(1,:));
            matched_q_poses = q_frames(1:2, model_corr(1, sol));
            figure; imshow(image); hold on;
            scatter(q_poses(1,:), q_poses(2,:), ['o' color]);
            gplot(W > 0.6, q_poses', ['-o' color]);
            scatter(matched_q_poses(1,:), matched_q_poses(2,:), ['o' color], 'filled');
            for j = 1:size(q_poses,2)
                text(q_poses(1,j), q_poses(2,j), num2str(j), 'Color', 'r');
            end
            title(obj_names{i}, 'Interpreter', 'none');
        end

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
    
    for i = 1 : length(top_indexes)
        hyp_i = top_indexes(i);
        fprintf('=== matching graph of %s ===\n', obj_names{hyp_i});
        
        % Separate data related to the hypothesis.
        [model_points, model_corr, ~, model_corr_dist] = separate_hyp_data(hyp_i, points, corr, cons2d, corr_dist);
        pcount = size(model_points, 2);
        retained = retained_corr{hyp_i};
        ret_corr = model_corr(:,retained);
        ret_corr_dist = model_corr_dist(retained);

        % Run graph matching.
        [sol, score, W] = graph_matching(ret_corr, ret_corr_dist, q_frames, model_points, models{hyp_i}, 'IsLocal', false, 'Method', 'sm');
        
        % Set solution and adjucency matrix of compatible correspondences.
        sol = logical(sol);
        adj_mat = W(sol, sol) > 0.9;
        adj_mat(logical(eye(size(adj_mat)))) = 0;
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
        if interactive
            color = colors{mod(hyp_i,length(colors))+1};
            q_poses = q_frames(1:2, ret_corr(1,:));
            matched_q_poses = q_frames(1:2, ret_corr(1, sol));
            figure; imshow(image); hold on;
            gplot(W > 0.9, q_poses', ['-o' color]);
            scatter(matched_q_poses(1,:), matched_q_poses(2,:), ['o' color], 'filled');
            title(['pairwise geometric compatibility: ' obj_names{hyp_i}], 'Interpreter', 'none');
        end
    end
    
end


function [sol, score, W] = graph_matching(model_corr, model_corr_dist, q_frames, model_points, model, varargin)
    is_local = true;
    interactive = false;
    method = 'rrwm';
    if nargin > 5
        i = 1;
        while i <= length(varargin)
            if strcmp(varargin{i}, 'IsLocal')
                is_local = varargin{i+1};
            elseif strcmp(varargin{i}, 'Method')
                method = varargin{i+1};
            elseif strcmp(varargin{i}, 'Interactive')
                interactive = varargin{i+1};
            end
            i = i + 2;
        end
    end
    
    [W, sol0] = affinity_matrix(model_corr, model_corr_dist, q_frames, model_points, model, is_local);
    
    if interactive
        figure; spy(W); 
    end

    ccount = size(model_corr, 2);
    pcount = size(model_points, 2);
    qcount = size(q_frames, 2);

    W(logical(eye(ccount))) = 0;
    
    if size(model_corr, 2) < 2 || nnz(W) < 3
        sol = sol0;
        score = sol0' * W * sol0;
        return;
    end

    % Create initial solution.
%     if strcmp(method, 'ipfp') || strcmp(method, 'ipfp_gm')
%         sol0 = ones(ccount,1);
%         sol0 = sol0/norm(sol0);
%         sol0 = zeros(ccount,1);
%     end

%     fprintf('running spectral matching ... ');
    
    switch method
        case 'sm' % Spectral matching
            [sol, stats_ipfp]  = spectral_matching_ipfp(W, model_corr(1,:), model_corr(2,:));
            score = stats_ipfp.best_score;
            
        case 'ipfp' % Integer fixed point maximizing x'Wx+Dx
%             D = -ones(ccount,1);
            D = zeros(ccount,1);
            [sol, x_opt, scores, score]  = ipfp(W, D, sol0, model_corr(1,:), model_corr(2,:), 50);
            
        case 'ipfp_gm' % Integer fixed point maximizing x'Wx
            [sol, stats_ipfp]  = ipfp_gm(W, sol0, model_corr(1,:), model_corr(2,:), 20);
            score = stats_ipfp.best_score;
            
        case 'rrwm' % Reweighted random walk matching
            [uniq_qindexes, ~, corr_qindexes] = unique(model_corr(1,:), 'stable');
            model_qcount = length(uniq_qindexes);
            group1 = logical(sparse(1:ccount, corr_qindexes, ones(ccount,1), ccount, model_qcount));
            group2 = logical(sparse(1:ccount, model_corr(2,:), ones(ccount,1), ccount, pcount));

            raw_sol = RRWM( W, group1, group2);

            sol = zeros(model_qcount, pcount);
            for i = 1 : ccount
                sol(model_corr(1,i) == uniq_qindexes, model_corr(2,i)) = raw_sol(i);
            end
            sol = discretisationMatching_hungarian(sol, ones(model_qcount, pcount));
            new_sol = zeros(size(raw_sol));
            for i = 1 : ccount
                new_sol(i) = sol(model_corr(1,i) == uniq_qindexes, model_corr(2,i));
            end
            sol = new_sol;
            score = sol' * W * sol;
            
        case 'gradient'
            [sol, score] = grad_ascent_gm(W, sol0);
    end
    
%     fprintf('done\n');

end


function [W, sol0] = affinity_matrix(model_corr, model_corr_dist, q_frames, model_points, model, is_local)
    ccount = size(model_corr,2);
    
    %%%%%% Create affinity matrix W.
%     fprintf('computing correspondences consistency matrix ... ');
    % Set non-diagonal elements of affinity matrix (affinity between two correspondences).
    if is_local
        [adj2d, nei_score2d] = consistency2d(model_corr, q_frames, model_points, 8);
        cons_covis = cons_covis3d(model_points, model.points, model_corr, ones(ccount));
        [adj3d, nei_score3d] = consistency3d(model_corr, model_points, model.points, cons_covis, 0.05);
        W = sqrt(nei_score2d .* nei_score3d);
        sol0 = double(any(adj2d & adj3d, 2));
    else
        [adj_geo, geo_score] = cons_pairwise_geo(model_corr, model_points, q_frames, model, ones(ccount), 0.8, 1.25);
        W = geo_score;
        sol0 = double(any(adj_geo, 2));
        for i = 1 : ccount
            same_q_pos = model_corr(1,:) == model_corr(1,i);
            same_p_pos = model_corr(2,:) == model_corr(2,i);
            W(i, same_q_pos | same_p_pos) = 0;
        end
        W = min(W, W');
    end
    
    % Normalize to [0,1].
    if max(W(:)) - min(W(:)) ~= 0
        W = (W - min(W(:))) / (max(W(:)) - min(W(:)));
    end

%     sol0 = double(any(W > 0.7, 2));

    % Set diagonal elements of affinity matrix.
    d = 1 ./ (model_corr_dist + 1);
    
    % Normalize main diagonal to [0,1].
    if max(d) - min(d) ~= 0
        W(logical(eye(ccount))) = (d - min(d)) / (max(d) - min(d));
    else
        W = d;
    end
%     W(logical(eye(ccount))) = 0;
    
    W = sparse(W);
    
    if numel(W) == 0
        W = 0;
    end
%     fprintf('done\n');
end
