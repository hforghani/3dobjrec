function pnt_adj_mat = cons_covis3d( points, points_arr )
% Get adjucency matrix of covisibility graph of correspondences. There is
% an edge between two nodes if their 3d points are covisible in any camera.

points_count = size(points,2);

% Put 3d point poses in a 3*P matrix.
point_instances = cell(1, points_count);
for i = 1:points_count
    point_instances{i} = points_arr{points(2,i)};
end

% Find camera indexes in which each point is visible.
cam_indexes = cell(points_count, 1);
for i = 1:points_count
    cam_indexes{i} = point_instances{i}.cameras_visible_in();
end

% Construct points covisibility graph.
pnt_adj_mat = false(points_count);
for i = 1 : points_count - 1
    for j = i+1 : points_count
        pnt_adj_mat(i, j) = ~isempty(intersect(cam_indexes{i}, cam_indexes{j}));
    end
end
pnt_adj_mat = pnt_adj_mat | pnt_adj_mat';

end
