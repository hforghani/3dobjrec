function adj_mat = cons_global(model_corr, q_frames, model_points, model, local_cons)
% correspondences :     2*C matrix
% query_frames :        4*Q matrix
% point :               2*P matrix
% model :               instance of Model
% local_cons :          C*C adjucency matrix of local consistency
% adj_mat :             C*C adjucency matrix of general consistency
    
    corr_count = size(model_corr, 2);
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
    [adj_mat, ~] = cons_pairwise_geo(model_corr, model_points, q_frames, model, adj_mat, MIN_TOLER, MAX_TOLER);

    % Add covisibility check.
    covis_adj_mat = cons_covis3d(model_points, model.points, model_corr, adj_mat);
    for i = 1 : corr_count
        adj_mat(i, :) = adj_mat(i, :) & covis_adj_mat(model_corr(2,i), model_corr(2,:));
    end

end

