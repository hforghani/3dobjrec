function adj_mat = consistency2d(correspondences, query_frames, scale_factor)
% Calculate adjucency matrix of 2d consistency graph.

if ~exist('scale_factor', 'var')
    scale_factor = 100;
end
query_poses = query_frames(1:2, :);
corr_count = size(correspondences, 2);

% Find nearest neighbors for each query pose.
corr_poses = query_poses(:, correspondences(1,:));
nei_num = max(floor(corr_count / 10) , 2);
kdtree = vl_kdtreebuild(double(corr_poses));
[nei_indexes, distances] = vl_kdtreequery(kdtree, corr_poses, corr_poses, 'NUMNEIGHBORS', nei_num);

% Construct graph of 2d local consistency.
adj_mat = false(corr_count);
for i = 1:corr_count
    nn_i = nei_indexes(:, i);
    dist_i = distances(:, i);
    % Check neighborhood distance.
    nn_i = nn_i(dist_i < scale_factor * query_frames(3, correspondences(1,i)));
    adj_mat(i, nn_i) = 1;
end

% Make the matrix symmetric and with zero diagonal.
adj_mat = adj_mat | adj_mat';
adj_mat = adj_mat .* ~eye(corr_count);


end
