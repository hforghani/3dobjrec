function [sel_model_i, sel_corr, sel_adj_mat] = match_corr_graph(q_frames, points, corr, corr_dist, models, obj_names, q_im_name)

%     global colors image;
    image = imread(q_im_name);
    colors = {'r','g','b','c','m','y','k','w'};
    
    % 2d local consistency
    cons2d = consistency2d(corr, q_frames, 100);
%     q_poses = q_frames(1:2, :);
%     figure(1); imshow(image); hold on;
%     gplot(cons2d, q_poses(:,corr(1,:))', '-.');
    
    model_count = length(models);
    qcount = size(q_frames,2);    
    confidences = zeros(model_count, 1);
    adj_matrices = cell(model_count, 1);
    
    for i = 1 : model_count
        fprintf('validating hyp "%s" graph ... ', obj_names{i});
        
        % Separate data related to the hypothesis.
        [model_points, model_corr, ~, model_cons2d] = separate_hyp_data(i, points, corr, corr_dist, cons2d);
        pcount = size(model_points, 2);
        
        % 3d local consistency
        pnt_adj_covis = cons_covis3d(model_points, models{i}.points, model_corr, model_cons2d);
        cons3d = consistency3d(model_corr, model_points, models{i}.points, pnt_adj_covis);
        
        % Calculate hypothesis confidence.
        local_cons = model_cons2d & cons3d;
        conf = sum(sum(local_cons));
        confidences(i) = conf;
        adj_matrices{i} = local_cons;
        
        fprintf('confidence = %d\n', conf);
    end
    
    % Choose top hypotheses.
    [~, sort_indexes] = sort(confidences, 'descend');
    N = 5;
    N = min(N, length(confidences));
    top_indexes = sort_indexes(1:N);
    fprintf('===== %d top hypotheses chose\n', N);

    sel_model_i = zeros(N, 1);
    sel_corr = cell(N, 1);
    sel_adj_mat = cell(N, 1);
    
    for i = 1 : length(top_indexes)
        hyp_i = top_indexes(i);
        fprintf('matching graph of %s ... ', obj_names{hyp_i});
        
        figure(3); subplot(2,3,i); title(obj_names{hyp_i});

        % Separate data related to the hypothesis.
        [model_points, model_corr, model_corr_dist, ~] = separate_hyp_data(hyp_i, points, corr, corr_dist, cons2d);
        local_cons = adj_matrices{hyp_i};
        pcount = size(model_points, 2);

%         [X12, X_SMAC, timing] = graph_match_SMAC(model_corr, model_corr_dist, local_cons, qcount, pcount);
%         fprintf('number of final matches: %d\n', nnz(X12));
        
        [matched_corr_i, stats_ipfp] = graph_matching_spectral(model_corr, model_corr_dist, local_cons, qcount, pcount);
        matched_corr = model_corr(:, logical(matched_corr_i));
        fprintf('number of final matches: %d\n', nnz(matched_corr_i));
        
        sel_model_i(i) = hyp_i;
        sel_corr{i} = matched_corr;

        % Plot consistency graph of query poses
        color = colors{mod(i,length(colors))+1};
        figure; imshow(image); hold on;
        scatter(q_frames(1,:), q_frames(2,:), ['o' color]);
        matched_q_poses = q_frames(1:2, matched_corr(1, :));
        scatter(matched_q_poses(1,:), matched_q_poses(2,:), ['o' color], 'filled');
        title(obj_names{hyp_i}, 'Interpreter', 'none');
    end
    
end



function [X12, X_SMAC, timing] = graph_match_SMAC(model_corr, model_corr_dist, local_cons, qcount, pcount)

    % Create matrix of feasible matches.
    ccount = size(model_corr, 2);
    E12 = zeros(qcount, pcount);
    for j = 1 : ccount
        E12(model_corr(1,j), model_corr(2,j)) = 1;
    end

    % Create sparse symmetric W.
    W = zeros(ccount);
    [row, col] = find(E12);
    for j = 1 : ccount
        q_index = row(j);
        p_index = col(j);
        corr_index_j = model_corr(1,:) == q_index & model_corr(2,:) == p_index;
        for k = j : ccount
            q_index = row(k);
            p_index = col(k);
            corr_index_k = model_corr(1,:) == q_index & model_corr(2,:) == p_index;
            if j == k || local_cons(corr_index_j,corr_index_k)
                W(j,k) = 1 / ((model_corr_dist(corr_index_j) + 1) * (model_corr_dist(corr_index_k) + 1));
            end
        end
    end
    W = W + W';
    W(logical(eye(size(W)))) = diag(W) / 2;
    W = sparse(W);
    spy(W);

    % Options for graph matching (discretization, normalization)
    options.constraintMode='both'; %'both' for 1-1 graph matching
    options.isAffine=1;% affine constraint
    options.isOrth=1;%orthonormalization before discretization
    options.normalization='iterative';%bistochastic kronecker normalization
    % options.normalization='none'; %we can also see results without normalization
    options.discretisation=@discretisationGradAssignment; %function for discretization
    options.is_discretisation_on_original_W=0;    

    % Spectral graph matching with affine constraint (SMAC)
    [X12, X_SMAC, timing] = compute_graph_matching_SMAC(W, E12, options);

end


function [sol_ipfp, stats_ipfp] = graph_matching_spectral(model_corr, model_corr_dist, local_cons, qcount, pcount)

    % Create sparse symmetric W.
    ccount = size(model_corr,2);
    W = zeros(ccount);
    for i = 1 : ccount
        for j = i : ccount
            if i == j || local_cons(i,j)
                W(i,j) = 1 / ((model_corr_dist(i) + 1) * (model_corr_dist(j) + 1));
            end
        end
    end
    W = W + W';
    W(logical(eye(size(W)))) = diag(W) / 2;
    W = sparse(W);
    spy(W);

    % Create initial solution.
    sol0 = ones(ccount,1);
    sol0 = sol0/norm(sol0);
    
    % Spectral graph matching
    [sol_ipfp, stats_ipfp]  = ipfp_gm(W, sol0, model_corr(1,:), model_corr(2,:));

end
