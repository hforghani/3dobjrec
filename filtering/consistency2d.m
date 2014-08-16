function [adj_mat, nei_score] = consistency2d(corr, q_frames, points, varargin)
% Calculate adjucency matrix of 2d consistency graph.

scale_factor = 8;
calc_scores = false;
if nargin > 3
    i = 1;
    while i <= length(varargin)
        if strcmp(varargin{i}, 'ScaleFactor')
            scale_factor = varargin{i+1};
        elseif strcmp(varargin{i}, 'CalcScores')
            calc_scores = true;
            i = i - 1;
        end
        i = i + 2;
    end
end

query_poses = q_frames(1:2, :);
corr_count = size(corr, 2);

adj_mat = false(corr_count);
if calc_scores
    nei_score = zeros(corr_count);
else
    nei_score = [];
end

if corr_count <= 1
    return;
end

% Find nearest neighbors for each query pose.
corr_poses = query_poses(:, corr(1,:));
nei_num = max(floor(corr_count / 5) , 2);
kdtree = vl_kdtreebuild(double(corr_poses));
[nei_indexes, distances] = vl_kdtreequery(kdtree, corr_poses, corr_poses, 'NUMNEIGHBORS', nei_num);
distances = sqrt(distances);

% Construct graph of 2d local consistency.
for i = 1:corr_count
    nn_i = nei_indexes(:, i);
    dist_i = distances(:, i);
    dist_thr = scale_factor * q_frames(3, corr(1,i));
    
    % Check neighborhood distance of correspondences of the same model.
    fil_nn_i = nn_i(dist_i < dist_thr);
    same_model = points(1, corr(2,i)) == points(1, corr(2, fil_nn_i));
    adj_mat(i, fil_nn_i(same_model)) = 1;
    
    % Set neighborhood score.
    if calc_scores
        s = 2 * dist_thr;
        nei_score(i, nn_i) = exp(-.5 * (dist_i/s) .^ 2);
    end
end

% Make the matrix symmetric and with zero diagonal.
adj_mat = adj_mat | adj_mat';
adj_mat(logical(eye(corr_count))) = 0;

if calc_scores
    nei_score = max(nei_score, nei_score');
    nei_score(logical(eye(corr_count))) = 0;
end

end
