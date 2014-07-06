function [model_points, model_corr, model_corr_dist, model_cons2d] = separate_hyp_data(i, points, corr, corr_dist, cons2d)
% Separate points, correspondences and their distances, and 2d consistency adjucency matrix related to the hypothesis i.

    is_of_model = points(1,:) == i;
    model_indexes = find(is_of_model);
    model_points = points(:, is_of_model);
    model_corr_indexes = ismember(corr(2,:), model_indexes);
    model_corr = corr(:, model_corr_indexes);
    model_corr(2,:) = reindex_arr(model_indexes, model_corr(2,:));
    model_corr_dist = corr_dist(:, model_corr_indexes);
    model_cons2d = cons2d(model_corr_indexes, model_corr_indexes);
    
end
