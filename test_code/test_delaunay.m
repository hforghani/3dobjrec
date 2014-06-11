addpath model;
model_f_name = 'data/model/axe_knight';
load(model_f_name);
points_count = length(model.points);
poses = zeros(3, points_count);

for i = 1:points_count
    poses(:,i) = model.points{i}.pos;
end

scatter3(poses(1,:), poses(2,:), poses(3,:));

figure;
tri = delaunay(poses(1,:), poses(2,:), poses(3,:));
trisurf(tri, poses(1,:), poses(2,:), poses(3,:));
