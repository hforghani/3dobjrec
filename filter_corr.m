function filtered_indexes = filter_corr(matches2d, matches3d, match_model_indexes, match_point_indexes)

models = unique(match_model_indexes);
model_count = length(models);
filtered_indexes = [];

for i = 1 : model_count
    model = models(i);
    model_indexes = match_model_indexes == model;
    model_real_indexes = find(model_indexes);
    model_matches2d = matches2d(:, model_indexes);
    kdtree = vl_kdtreebuild(double(model_matches2d));
    
    [~, distances] = vl_kdtreequery(kdtree, model_matches2d, model_matches2d, 'NUMNEIGHBORS', 2);
    nearest_nei = distances(2, :);
    model_filtered_indexes = nearest_nei < 100;
    filtered_indexes = [filtered_indexes, model_real_indexes(model_filtered_indexes)];
end

end