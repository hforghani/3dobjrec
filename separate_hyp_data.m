function [model_points, model_corr, model_cons2d, model_corr_dist] = separate_hyp_data(i, points, corr, cons2d, corr_dist)
% Separate points, correspondences and their distances, and 2d consistency adjucency matrix related to the hypothesis i.

    is_of_model = points(1,:) == i;
    model_indexes = find(is_of_model);
    model_points = points(:, is_of_model);
    model_corr_indexes = ismember(corr(2,:), model_indexes);
    model_corr = corr(:, model_corr_indexes);
    model_corr(2,:) = reindex_arr(model_indexes, model_corr(2,:));
    if exist('cons2d', 'var') && ~isempty(cons2d)
        model_cons2d = cons2d(model_corr_indexes, model_corr_indexes);
    else
        model_cons2d = [];
    end
    if exist('corr_dist', 'var') && ~isempty(corr_dist)
        model_corr_dist = corr_dist(:, model_corr_indexes);
    else
        model_corr_dist = [];
    end
    
end
