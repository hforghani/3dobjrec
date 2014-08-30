function adj_mat = neighbor3d( model, nei_ratio_3d )

pcount = length(model.points);
nei_num = floor(pcount * nei_ratio_3d);

poses = model.get_poses();

% Find spatially close points.
kdtree = vl_kdtreebuild(double(poses));
[indexes, ~] = vl_kdtreequery(kdtree, poses, poses, 'NUMNEIGHBORS', nei_num + 1);
indexes(1,:) = [];

adj_mat = false(pcount);

% Construct graph of 3d distances.
for i = 1 : pcount
    adj_mat(i, indexes(:, i)) = 1;
end

% Make the matrices symmetric and with zero diagonal.
adj_mat = adj_mat | adj_mat';
adj_mat(logical(eye(pcount))) = 0;

end