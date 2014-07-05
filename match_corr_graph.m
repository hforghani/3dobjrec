function [sel_model_i, sel_corr, sel_adj_mat] = match_corr_graph(q_frames, points, corr, corr_dist, models, obj_names, q_im_name)

    addpath utils;
    
    global colors image;
    image = imread(q_im_name);
    colors = {'r','g','b','c','m','y','k','w'};
    
    % 2d local consistency
    cons2d = consistency2d(corr, q_frames, 100);
%     q_poses = q_frames(1:2, :);
%     figure(1); imshow(image); hold on;
%     gplot(cons2d, q_poses(:,corr(1,:))', '-.');
    
    points_model_indexes = points(1,:);
    model_count = length(models);
    qcount = size(q_frames,2);    
    
    for i = 1 : model_count
        fprintf('matching hyp "%s" graph ... ', obj_names{i});
        
        % Separate points and correspondences related to this model.
        is_of_model = points_model_indexes == i;
        model_indexes = find(is_of_model);
        model_points = points(:, is_of_model);
        model_corr_indexes = ismember(corr(2,:), model_indexes);
        model_corr = corr(:, model_corr_indexes);
        model_corr(2,:) = reindex_arr(model_indexes, model_corr(2,:));
        model_corr_dist = corr_dist(:, model_corr_indexes);
        model_cons2d = cons2d(model_corr_indexes, model_corr_indexes);
        ccount = size(model_corr, 2);
        pcount = size(model_points, 2);
        
        % 3d local consistency
        pnt_adj_covis = cons_covis3d(model_points, models{i}.points);
        cons3d = consistency3d(model_corr, model_points, models{i}.points, pnt_adj_covis);
        
        % Calculate hypothesis confidence.
        local_cons = model_cons2d & cons3d;
        confidence = sum(sum(local_cons));
        
        if confidence > 100
            % Create matrix of feasible matches.
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
                corr_index_i = model_corr(1,:) == q_index & model_corr(2,:) == p_index;
                for k = j : ccount
                    if j == k || (model_cons2d(j,k) && cons3d(j,k))
                        q_index = row(k);
                        p_index = col(k);
                        corr_index_j = model_corr(1,:) == q_index & model_corr(2,:) == p_index;
                        W(j,k) = 1 / ((model_corr_dist(corr_index_i) + 1) * (model_corr_dist(corr_index_j) + 1));
                    end
                end
            end
            W = W + W';
            W(logical(eye(size(W)))) = diag(W) / 2;
            W = sparse(W);
            figure(2); spy(W);

            % Options for graph matching (discretization, normalization)
            options.constraintMode='both'; %'both' for 1-1 graph matching
            options.isAffine=1;% affine constraint
            options.isOrth=1;%orthonormalization before discretization
            options.normalization='iterative';%bistochastic kronecker normalization
            % options.normalization='none'; %we can also see results without normalization
            options.discretisation=@discretisationGradAssignment; %function for discretization
            options.is_discretisation_on_original_W=0;    

            % Match graphs.
            [X12, X_SMAC, timing] = compute_graph_matching_SMAC(W, E12, options);
            fprintf('number of final matches: %d\n', nnz(X12));
        else
            fprintf('low confidence\n');
        end
    end
    
end
