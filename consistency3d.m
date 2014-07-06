function adj_mat = consistency3d( correspondences, points, points_arr, covis_mat )
% Get adjucency matrix of 3d local consistency matrix of correspondences.
% correspondences: correspondences related to points of an object
% points: 2*P matrix of points of an abject; each column contains model
% index and point index
% points_arr: cell array of object points of type Point

points_count = size(points,2);
nei_num = floor(length(points_arr) * 0.05);

% Put 3d point poses in a 3*P matrix.
all_poses = zeros(3, length(points_arr));
for i = 1:length(points_arr)
    all_poses(:,i) = points_arr{i}.pos;
end
point_poses = all_poses(:, points(2, :));

% Find spatially close points.
kdtree = vl_kdtreebuild(double(all_poses));
[indexes, ~] = vl_kdtreequery(kdtree, all_poses, point_poses, 'NUMNEIGHBORS', nei_num + 1);
indexes(1,:) = [];

% Construct graph of 3d local consistency.
pnt_adj_mat = false(points_count);
for i = 1:points_count
    nn_i = indexes(:, i);
    [~, inn, ~] = intersect(nn_i, points(2, covis_mat(i, :)));
    sorted_inn = sort(inn);
    nei_indexes = nn_i(sorted_inn(1:min(nei_num, length(sorted_inn))));
    [~, ipoints, ~] = intersect(points(2,:), nei_indexes);
    pnt_adj_mat(i, ipoints) = 1;
end

% Make the matrix symmetric and with zero diagonal.
pnt_adj_mat = pnt_adj_mat | pnt_adj_mat';
pnt_adj_mat = pnt_adj_mat .* ~eye(points_count);

% Construct correspondences 3d local consistency graph.
corr_count = size(correspondences, 2);
adj_mat = false(corr_count);
for i = 1 : corr_count
    adj_mat(i, :) = pnt_adj_mat(correspondences(2,i), correspondences(2,:));
end

end