function distances = dist3d( model, nei_ratio_3d )

pcount = length(model.points);
nei_num = floor(pcount * nei_ratio_3d);

poses = model.get_poses();

% Find spatially close points.
kdtree = vl_kdtreebuild(double(poses));
[indexes, dist] = vl_kdtreequery(kdtree, poses, poses, 'NUMNEIGHBORS', nei_num + 1);
dist = sqrt(dist);
indexes(1,:) = [];
dist(1,:) = [];

distances = zeros(pcount);

% Construct graph of 3d distances.
for i = 1 : pcount
    distances(i, indexes(:, i)) = dist(:,i);
end

% Make the matrices symmetric and with zero diagonal.
distances = max(distances, distances');
distances(logical(eye(pcount))) = 0;

end