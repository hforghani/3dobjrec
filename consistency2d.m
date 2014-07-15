function [adj_mat, nei_score] = consistency2d(corr, q_frames, points, scale_factor)
% Calculate adjucency matrix of 2d consistency graph.

if ~exist('scale_factor', 'var')
    scale_factor = 100;
end
query_poses = q_frames(1:2, :);
corr_count = size(corr, 2);

% Find nearest neighbors for each query pose.
corr_poses = query_poses(:, corr(1,:));
nei_num = max(floor(corr_count / 10) , 2);
kdtree = vl_kdtreebuild(double(corr_poses));
[nei_indexes, distances] = vl_kdtreequery(kdtree, corr_poses, corr_poses, 'NUMNEIGHBORS', nei_num);
nei_indexes(1, :) = [];
distances(1, :) = [];

% Construct graph of 2d local consistency.
adj_mat = false(corr_count);
nei_score = zeros(corr_count);
fil_dist = [];
for i = 1:corr_count
    nn_i = nei_indexes(:, i);
    dist_i = distances(:, i);
    
    % Check neighborhood distance of correspondences of the same model.
    fil_nn_i = nn_i(dist_i < scale_factor * q_frames(3, corr(1,i)));
    same_model = points(1, corr(2,i)) == points(1, corr(2, fil_nn_i));
    fil_nn_i = fil_nn_i(same_model);
    adj_mat(i, fil_nn_i) = 1;
    
    % Set neighborhood score.
    sigma = scale_factor * q_frames(3, corr(1,i));
    nei_score(i, nn_i) = exp(-.5 * (dist_i/sigma) .^ 2);
    
    fil_dist = [fil_dist; dist_i(dist_i < scale_factor * q_frames(3, corr(1,i)))];
end

% Make the matrix symmetric and with zero diagonal.
adj_mat = adj_mat | adj_mat';
adj_mat(logical(eye(corr_count))) = 0;

nei_score = max(nei_score, nei_score');
nei_score(logical(eye(corr_count))) = 0;

end
