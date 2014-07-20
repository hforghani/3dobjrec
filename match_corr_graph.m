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
        [matched_corr_i, score, W] = graph_matching_spectral(model_corr, model_corr_dist, q_frames, model_points, models{i}, true);
        matched_corr_i = logical(matched_corr_i);
        confidences(i) = sum(matched_corr_i);
        retained_corr{i} = matched_corr_i;
        adj_mat = W > 0.5;
        
        % by SMAC
%         [X12, matched_corr_i, timing, W] = graph_match_SMAC(model_corr, model_corr_dist, q_frames, model_points, models{i}, true);
        
        % Plot matched correspondences.
%         color = colors{mod(i,length(colors))+1};
%         q_poses = q_frames(1:2, model_corr(1,:));
%         matched_q_poses = q_frames(1:2, model_corr(1, matched_corr_i));
%         figure(i);
% %         subplot(1,2,1);
%         imshow(image); hold on;
%         scatter(q_poses(1,:), q_poses(2,:), ['o' color]);
%         gplot(adj_mat, q_poses', ['-o' color]);
%         scatter(matched_q_poses(1,:), matched_q_poses(2,:), ['o' color], 'filled');
%         title(obj_names{i}, 'Interpreter', 'none');

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

%         [X12, matched_corr_i, timing, W] = graph_match_SMAC(model_corr(:,retained), model_corr_dist(retained), q_frames, model_points, models{hyp_i}, false);
%         fprintf('number of final matches: %d\n', nnz(X12));
        
        [matched_corr_i, score, W] = graph_matching_spectral(ret_corr, ret_corr_dist, q_frames, model_points, models{hyp_i}, false);
        matched_corr_i = logical(matched_corr_i);
        adj_mat = W > 0.9;
        fprintf('number of final matches: %d\n', nnz(matched_corr_i));

%         title(obj_names{hyp_i}, 'Interpreter', 'none');

        sel_model_i(i) = hyp_i;
        points_model_indexes = points(1,:);
        model_indexes = find(points_model_indexes == hyp_i);
        model_corr_indexes = ismember(corr(2,:), model_indexes);
        sel_corr{i} = corr(:, model_corr_indexes);
        ret_indexes = find(retained);
        sel_corr{i} = sel_corr{i}(:, ret_indexes(matched_corr_i));
        sel_adj_mat{i} = adj_mat;

        % Plot matched correspondences.
%         color = colors{mod(hyp_i,length(colors))+1};
%         q_poses = q_frames(1:2, ret_corr(1,:));
%         matched_q_poses = q_frames(1:2, ret_corr(1, matched_corr_i));
%         figure;
% %         subplot(1,2,1);
%         imshow(image); hold on;
%         gplot(adj_mat, q_poses', ['-o' color]);
%         scatter(matched_q_poses(1,:), matched_q_poses(2,:), ['o' color], 'filled');
%         title(['pairwise geometric compatibility: ' obj_names{hyp_i}], 'Interpreter', 'none');
    end
    
end



function [X12, X_SMAC, timing, W_SMAC] = graph_match_SMAC(model_corr, model_corr_dist, q_frames, model_points, model, is_local, interactive)

    if nargin == 6
        interactive = false;
    end

    % Create matrix of feasible matches.
    ccount = size(model_corr, 2);
    pcount = size(model_points, 2);
    qcount = size(q_frames, 2);
    E12 = zeros(qcount, pcount);
    for j = 1 : ccount
        E12(model_corr(1,j), model_corr(2,j)) = 1;
    end
    
    % Compute affinity matrix.
    W = affinity_matrix(model_corr, model_corr_dist, q_frames, model_points, model, is_local);

    % Create affinity matrix in the format of SMAC function input.
    W_SMAC = zeros(ccount);
    [row, col] = find(E12);
    for j = 1 : ccount
        q_index = row(j);
        p_index = col(j);
        corr_index_j = model_corr(1,:) == q_index & model_corr(2,:) == p_index;
        for k = j : ccount
            q_index = row(k);
            p_index = col(k);
            corr_index_k = model_corr(1,:) == q_index & model_corr(2,:) == p_index;
            W_SMAC(j,k) = W(corr_index_j, corr_index_k);
        end
    end
    W_SMAC = W_SMAC + W_SMAC';
    W_SMAC(logical(eye(size(W_SMAC)))) = diag(W_SMAC) / 2;
    W_SMAC = sparse(W_SMAC);
    if interactive
        spy(W_SMAC);
    end

    % Options for graph matching (discretization, normalization)
    options.constraintMode='both'; %'both' for 1-1 graph matching
    options.isAffine=1;% affine constraint
    options.isOrth=1;%orthonormalization before discretization
    options.normalization='iterative';%bistochastic kronecker normalization
    % options.normalization='none'; %we can also see results without normalization
    options.discretisation=@discretisationGradAssignment; %function for discretization
    options.is_discretisation_on_original_W=0;    

    % Spectral graph matching with affine constraint (SMAC)
    [X12, X_SMAC, timing] = compute_graph_matching_SMAC(W_SMAC, E12, options);

end


function [sol, score, W] = graph_matching_spectral(model_corr, model_corr_dist, q_frames, model_points, model, is_local, interactive)
    if nargin == 6
        interactive = false;
    end

    W = affinity_matrix(model_corr, model_corr_dist, q_frames, model_points, model, is_local);
    
    if interactive
        spy(W);
    end

    % Create initial solution.
    ccount = size(model_corr, 2);
    sol0 = ones(ccount,1);
    sol0 = sol0/norm(sol0);
    
    % Spectral graph matching
%     fprintf('running spectral matching ... ');
    [sol, stats_ipfp]  = ipfp_gm(W, sol0, model_corr(1,:), model_corr(2,:));
    score = stats_ipfp.best_score;
%     fprintf('done\n');

end


function W = affinity_matrix(model_corr, model_corr_dist, q_frames, model_points, model, is_local)
    ccount = size(model_corr,2);
    
    if is_local
%         fprintf('computing 2d local consistency ... ');
        [~, nei_score2d] = consistency2d(model_corr, q_frames, model_points, 8);
%         fprintf('done\n');
%         fprintf('computing 3d covisibility ... ');
        cons_covis = cons_covis3d(model_points, model.points, model_corr, ones(ccount));
%         fprintf('done\n');
%         fprintf('computing 3d local consistency ... ');
        [~, nei_score3d] = consistency3d(model_corr, model_points, model.points, cons_covis, 0.05);
%         fprintf('done\n');
    else
%         fprintf('computing pairwise geometric consistency ... ');
        [~, geo_cons] = cons_pairwise_geo(model_corr, model_points, q_frames, model, ones(ccount), 0.8, 1.25);
%         fprintf('done\n');
    end

    % Create sparse symmetric W.
%     fprintf('computing correspondences consistency matrix ... ');
    W = zeros(ccount);
    for i = 1 : ccount
        for j = i : ccount
            if i == j
                W(i,i) = 1 / (model_corr_dist(i) + 1);
%                 W(i,i) = 1;
%                 W(i,i) = 0;
            else
                if is_local
                    W(i,j) = sqrt(nei_score2d(i,j) * nei_score3d(i,j));
%                     W(i,j) = nei_score2d(i,j);
                else
                    if any(model_corr(:,i) == model_corr(:,j))
                        W(i,j) = 0;
                    else
                        W(i,j) = geo_cons(i,j);
%                        W(i,j) = geo_cons(i,j) * nei_score2d(i,j) * nei_score3d(i,j);
                    end
                end
            end
        end
    end
    W = W + W';
    W(logical(eye(size(W)))) = diag(W) / 2;
    W = sparse(W);
%     fprintf('done\n');
end
