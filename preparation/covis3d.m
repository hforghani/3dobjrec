function adj_mat = covis3d( model )
% Get adjucency matrix of covisibility graph of correspondences. There is
% an edge between two nodes if their 3d points are covisible in any camera.
% If corr and corr_cons are given, check covisibility just for points with 
% any consistent correspondence.

pcount = length(model.points);

% Find camera indexes in which each point is visible.
% cam_indexes = cell(pcount, 1);
% for i = 1:pcount
%     cam_indexes{i} = model.points{i}.cameras_visible_in();
% end
% 
% 
% % Construct points covisibility graph.
% adj_mat = false(pcount);
% for i = 1 : pcount
%     for j = i+1 : pcount
%         adj_mat(i, j) = has_intersect(cam_indexes{i}, cam_indexes{j});
%     end
% end

cam_count = length(model.cameras);
cam_pnt_indexes = cell(cam_count, 1);
for i = 1 : pcount
    cam_i = model.points{i}.cameras_visible_in();
    for j = 1 : length(cam_i)
        cam_pnt_indexes{cam_i(j)} = [cam_pnt_indexes{cam_i(j)}, i];
    end
end

adj_mat = false(pcount);

for i = 1 : cam_count
    pnt_i = cam_pnt_indexes{i};
    combs = nchoosek(1 : length(pnt_i), 2);
    indexes = sub2ind(size(adj_mat), pnt_i(combs(:,1)), pnt_i(combs(:,2)));
    adj_mat(indexes) = 1;
end

adj_mat = adj_mat | adj_mat';

end
