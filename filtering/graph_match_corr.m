function [sel_model_i, sel_corr, sel_adj_mat] = graph_match_corr(q_frames, ...
    points, corr, corr_dist, models, obj_names, q_im_name, options, interactive)

    if nargin < 9
        interactive = 0;
    end
    
    image = imread(q_im_name);
    colors = {'r','g','b','c','m','y','k','w'};
    
    model_count = length(models);
    qcount = size(q_frames,2);    
    confidences = zeros(model_count, 1);
    retained_corr = cell(model_count, 1);
    
    for i = 1 : model_count
        if interactive; fprintf('local filter of "%s" ... ', obj_names{i}); end
        
        % Separate data related to the hypothesis.
        [model_points, model_corr, ~, model_corr_dist] = separate_hyp_data(i, points, corr, [], corr_dist);
       
        % Compute confidence by graph matching.
        switch options.local
            case 'gradient'
                [sol, score, W] = graph_matching(model_corr, model_corr_dist, q_frames, model_points, models{i}, options, 'Affinity', 'local', 'Method', 'gradient');
                sol = logical(sol);
                confidences(i) = score;
                adj_mat = W > 0.6;
                
            case 'hao'
                model_cons2d = consistency2d(model_corr, q_frames, model_points, options);
                pnt_adj_covis = cons_covis3d(model_points, models{i}.points, model_corr, model_cons2d);
                adj_mat_3d = consistency3d(model_corr, model_points, models{i}.points, pnt_adj_covis, options);
                adj_mat = model_cons2d & adj_mat_3d;
                sol = any(adj_mat);
                confidences(i) = sum(sum(adj_mat));
                
            case 'sm'
                [sol, score, W] = graph_matching(model_corr, model_corr_dist, q_frames, model_points, models{i}, options, 'Affinity', 'local', 'Method', 'sm');
                sol = logical(sol);
                confidences(i) = score;
                adj_mat = W > 0.6;

            case 'ipfp'
                [sol, score, W] = graph_matching(model_corr, model_corr_dist, q_frames, model_points, models{i}, options, 'Affinity', 'local', 'Method', 'ipfp_gm');
                sol = logical(sol);
                confidences(i) = score;
                adj_mat = W > 0.6;

            case 'rrwm'
                [sol, score, W] = graph_matching(model_corr, model_corr_dist, q_frames, model_points, models{i}, options, 'Affinity', 'local', 'Method', 'rrwm');
                sol = logical(sol);
                confidences(i) = score;
                adj_mat = W > 0.6;
        end
        
        retained_corr{i} = sol;

        % Plot matched correspondences.
        if interactive > 1
            color = colors{mod(i,length(colors))+1};
            q_poses = q_frames(1:2, model_corr(1,:));
            matched_q_poses = q_frames(1:2, model_corr(1, sol));
            figure; imshow(image); hold on;
            scatter(q_poses(1,:), q_poses(2,:), ['o' color]);
            gplot(adj_mat, q_poses', ['-o' color]);
            scatter(matched_q_poses(1,:), matched_q_poses(2,:), ['o' color], 'filled');
            for j = 1:size(q_poses,2)
                text(q_poses(1,j), q_poses(2,j), num2str(model_corr(1,j)), 'Color', 'r');
            end
            title(obj_names{i}, 'Interpreter', 'none');
        end

        if interactive; fprintf('confidence = %f\n', confidences(i)); end
    end
    
    % Choose top hypotheses.
    [~, sort_indexes] = sort(confidences, 'descend');
    options.top_hyp_num = min(options.top_hyp_num, length(confidences));
    top_indexes = sort_indexes(1:options.top_hyp_num);
    if interactive; fprintf('===== %d top hypotheses chose\n', options.top_hyp_num); end

    sel_model_i = zeros(options.top_hyp_num, 1);
    sel_corr = cell(options.top_hyp_num, 1);
    sel_adj_mat = cell(options.top_hyp_num, 1);
    
    for i = 1 : length(top_indexes)
        hyp_i = top_indexes(i);
        if interactive; fprintf('global filter of "%s"\n', obj_names{hyp_i}); end
        
        % Separate data related to the hypothesis.
        [model_points, model_corr, ~, model_corr_dist] = separate_hyp_data(hyp_i, points, corr, [], corr_dist);
        pcount = size(model_points, 2);
        retained = retained_corr{hyp_i};
        ret_corr = model_corr(:,retained);
        ret_ccount = size(ret_corr,2);
        ret_corr_dist = model_corr_dist(retained);
        
        adj_mat = [];

        % Global filter
        switch options.global
            case 'exhaust'
                adj_mat = true(ret_ccount);
                sol = true(ret_ccount,1);
                
            case 'hao'
                adj_mat = cons_global(ret_corr, q_frames, model_points, models{hyp_i}, ones(ret_ccount));
                sol = any(adj_mat);
                
            case 'geom'
                [adj_mat, score] = cons_pairwise_geo(ret_corr, model_points, q_frames, models{hyp_i}, ones(ret_ccount), 0.8, 1.25);
                W = score;
                for j = 1 : ret_ccount
                    same_q_pos = ret_corr(1,:) == ret_corr(1,j);
                    same_p_pos = ret_corr(2,:) == ret_corr(2,j);
                    W(j, same_q_pos | same_p_pos) = 0;
                    adj_mat(j, same_q_pos | same_p_pos) = 0;
                end
                adj_mat = adj_mat & adj_mat';
                sol = double(any(adj_mat, 2));
                
            case 'geomGradient'
                [sol, score, W] = graph_matching(ret_corr, ret_corr_dist, q_frames, model_points, models{hyp_i}, options, 'Affinity', 'geom', 'Method', 'gradient');
                adj_mat = W > 0.8;
                adj_mat(logical(eye(size(adj_mat)))) = 0;
                
            case 'geomSM'
                [sol, score, W] = graph_matching(ret_corr, ret_corr_dist, q_frames, model_points, models{hyp_i}, options, 'Affinity', 'geom', 'Method', 'sm');
                adj_mat = W > 0.8;
                adj_mat(logical(eye(size(adj_mat)))) = 0;
                
            case 'geomIPFP'
                [sol, score, W] = graph_matching(ret_corr, ret_corr_dist, q_frames, model_points, models{hyp_i}, options, 'Affinity', 'geom', 'Method', 'ipfp');
                adj_mat = W > 0.8;
                adj_mat(logical(eye(size(adj_mat)))) = 0;

            case 'geomRRWM'
                [sol, score, W] = graph_matching(ret_corr, ret_corr_dist, q_frames, model_points, models{hyp_i}, options, 'Affinity', 'geom', 'Method', 'rrwm');
                adj_mat = W > 0.8;
                adj_mat(logical(eye(size(adj_mat)))) = 0;

            case 'angle'
                [sol, score, W] = graph_matching(ret_corr, ret_corr_dist, q_frames, model_points, models{hyp_i}, options, 'Affinity', 'angle', 'Method', 'gradient');
                adj_mat = W ~= 0;
            
        end
        
        sol = logical(sol);

%         title(obj_names{hyp_i}, 'Interpreter', 'none');

        % Set global filter result for hypothesis i.
        sel_model_i(i) = hyp_i;
        points_model_indexes = points(1,:);
        model_indexes = find(points_model_indexes == hyp_i);
        model_corr_indexes = ismember(corr(2,:), model_indexes);
        sel_corr{i} = corr(:, model_corr_indexes);
        ret_indexes = find(retained);
        sel_corr{i} = sel_corr{i}(:, ret_indexes(sol));
        if ~isempty(adj_mat)
            if length(size(adj_mat)) == 2
                sel_adj_mat{i} = adj_mat(sol, sol);
            else
                sel_adj_mat{i} = adj_mat(sol, sol, sol);
            end
        end

        % Plot matched correspondences.
        if interactive > 1
            color = colors{mod(hyp_i,length(colors))+1};
            q_poses = q_frames(1:2, ret_corr(1,:));
            matched_q_poses = q_frames(1:2, ret_corr(1, sol));
            figure; imshow(image); hold on;
            if length(size(adj_mat)) == 2
                gplot(adj_mat, q_poses', ['-o' color]);
            elseif length(size(adj_mat)) == 3
                adj_mat = any(adj_mat,3);
                gplot(adj_mat, q_poses', ['-o' color]);
            end
            scatter(matched_q_poses(1,:), matched_q_poses(2,:), ['o' color], 'filled');
            title(['pairwise geometric compatibility: ' obj_names{hyp_i}], 'Interpreter', 'none');
        end
    end
    
end


function [sol, score, W] = graph_matching(model_corr, model_corr_dist, q_frames, model_points, model, options, varargin)
    affinity = 'local';
    method = 'gradient';
    if nargin > 5
        i = 1;
        while i <= length(varargin)
            if strcmp(varargin{i}, 'Affinity')
                affinity = varargin{i+1};
            elseif strcmp(varargin{i}, 'Method')
                method = varargin{i+1};
            end
            i = i + 2;
        end
    end
    
    if strcmp(affinity, 'angle'); method = 'gradient'; end
    
    ccount = size(model_corr, 2);
    pcount = size(model_points, 2);
    qcount = size(q_frames, 2);

    if ccount < 2
        sol = zeros(ccount,1);
        score = 0;
        W = zeros(ccount);
        return;
    end
    
    [W, sol0] = affinity_matrix(model_corr, model_corr_dist, q_frames, model_points, model, options, 'Criteria', affinity);
    
    if nnz(W) < 3
        sol = sol0;
        score = graph_match_score(sol, W);
        return;
    end

    switch method
        case 'sm' % Spectral matching
            [sol, stats_ipfp]  = spectral_matching_ipfp(W, model_corr(1,:), model_corr(2,:));
            score = stats_ipfp.best_score;
            
        case 'ipfp' % Integer fixed point maximizing x'Wx+Dx
%             D = -ones(ccount,1);
            D = zeros(ccount,1);
            [sol, x_opt, scores, score]  = ipfp(W, D, sol0, model_corr(1,:), model_corr(2,:), 50);
            
        case 'ipfp_gm' % Integer fixed point maximizing x'Wx
            [sol, stats_ipfp]  = ipfp_gm(W, sol0, model_corr(1,:), model_corr(2,:));
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
            score = graph_match_score(sol, W);
            
        case 'gradient'
            if length(size(W)) == 2
                [sol, score] = grad_ascent_gm(W, sol0);
            elseif length(size(W)) == 3
%                 guide_graph = any(W, 3);
                [sol, score] = grad_ascent_gm_tri(W, sol0);
            else
                error('invalid size of W for graph matching');
            end
    end
    
end


function [W, sol0] = affinity_matrix(model_corr, model_corr_dist, q_frames, model_points, model, options, varargin)
    criteria = 'local';
    
    i = 1;
    while i <= length(varargin)
        if strcmp(varargin{i}, 'Criteria')
            criteria = varargin{i+1};
        end
        i = i + 2;
    end
    
    ccount = size(model_corr,2);
    
    %%%%%% Create affinity matrix W.
%     fprintf('computing correspondences consistency matrix ... ');
    % Set non-diagonal elements of affinity matrix (affinity between two correspondences).
    switch criteria
        case 'local'
            [adj2d, nei_score2d] = consistency2d(model_corr, q_frames, model_points, options, 'CalcScores');
            cons_covis = cons_covis3d(model_points, model.points, model_corr, ones(ccount));
            [adj3d, nei_score3d] = consistency3d(model_corr, model_points, model.points, cons_covis, options, 'CalcScores');
            W = sqrt(nei_score2d .* nei_score3d);
            for i = 1 : ccount
                same_q_pos = model_corr(1,:) == model_corr(1,i);
                same_p_pos = model_corr(2,:) == model_corr(2,i);
                W(i, same_q_pos | same_p_pos) = 0;
            end
            W = min(W, W');
            sol0 = double(any(adj2d & adj3d, 2));
        case 'geom'
            [adj_geo, geo_score] = cons_pairwise_geo(model_corr, model_points, q_frames, model, ones(ccount), 0.8, 1.25);
            W = geo_score;
            for i = 1 : ccount
                same_q_pos = model_corr(1,:) == model_corr(1,i);
                same_p_pos = model_corr(2,:) == model_corr(2,i);
                W(i, same_q_pos | same_p_pos) = 0;
                adj_geo(i, same_q_pos | same_p_pos) = 0;
            end
            sol0 = double(any(adj_geo, 2));
            W = min(W, W');
        case 'angle'
            W = cons_tri_angle(model_corr, model_points, q_frames, model);
            w_sum = sum(sum(W,3),2);
            sol0 = double(w_sum > mean(w_sum));
    end
    
    % Normalize to [0,1].
    if ~islogical(W) && max(W(:)) - min(W(:)) ~= 0
        W = (W - min(W(:))) / (max(W(:)) - min(W(:)));
    end

%     sol0 = double(any(W > 0.7, 2));

    % Set diagonal elements of affinity matrix.
%     d = 1 ./ (model_corr_dist + 1);
%     if max(d) - min(d) ~= 0
%         W(logical(eye(ccount))) = (d - min(d)) / (max(d) - min(d)); % Normalize main diagonal to [0,1].
%     else
%         W = d;
%     end

    if length(size(W)) == 2
        W(logical(eye(size(W)))) = 0;
        W = sparse(W);
    end
    
    if numel(W) == 0
        W = 0;
    end
%     fprintf('done\n');
end
