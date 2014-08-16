function [adj_mat, nei_score] = consistency3d( corr, points, points_arr, covis_mat, options, varargin )
% Get adjucency matrix of 3d local consistency matrix of correspondences.
% correspondences: correspondences related to points of an object
% points: 2*P matrix of points of an abject; each column contains model
% index and point index
% points_arr: cell array of object points of type Point

calc_scores = false;
if nargin > 4
    i = 1;
    while i <= length(varargin)
        if strcmp(varargin{i}, 'CalcScores')
            calc_scores = true;
            i = i - 1;
        end
        i = i + 2;
    end
end

points_count = size(points,2);
corr_count = size(corr, 2);
nei_num = floor(length(points_arr) * options.nei_ratio_3d);

% Create output matrices.
adj_mat = false(corr_count);
if calc_scores
    nei_score = zeros(corr_count);
else
    nei_score = [];
end

if corr_count == 1
    return;
end

% Put 3d point poses in a 3*P matrix.
all_poses = zeros(3, length(points_arr));
for i = 1:length(points_arr)
    all_poses(:,i) = points_arr{i}.pos;
end
point_poses = all_poses(:, points(2, :));

% Find spatially close points.
kdtree = vl_kdtreebuild(double(all_poses));
[indexes, dist] = vl_kdtreequery(kdtree, all_poses, point_poses, 'NUMNEIGHBORS', nei_num + 1);
dist = sqrt(dist);
indexes(1,:) = [];
dist(1,:) = [];

% Construct graph of 3d local consistency.

if calc_scores
    s = options.sigma_mult_3d * min(dist(end, :));
end

for i = 1 : points_count
    nn_i = indexes(:, i);
    [nei_indexes, nni, ~] = intersect(nn_i, points(2, covis_mat(i, :)));
    for j = 1 : length(nei_indexes)
        ipoints = points(2, corr(2,:)) == nei_indexes(j);
        adj_mat(i, ipoints) = 1;
        if calc_scores
            dist_i = dist(nni(j), i);
            nei_score(i, ipoints) = exp(-.5 * (dist_i/s) .^ 2);
        end
    end
end

% Make the matrices symmetric and with zero diagonal.
adj_mat = adj_mat | adj_mat';
adj_mat = adj_mat .* ~eye(corr_count);
if calc_scores
    nei_score = max(nei_score, nei_score');
    nei_score(logical(eye(corr_count))) = 0;
end

end