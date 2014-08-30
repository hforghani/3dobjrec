function angles3d = angles3d(model, covis)

% start = tic;

pcount = length(model.points);
poses = model.get_poses();

point_dist = pdist(poses');
point_dist = squareform(point_dist);

% angles3d = Inf(pcount, pcount, pcount);

angles3d = cell(pcount, 1);

if isempty(covis)
    return;
end

for x = find(any(covis))
    
    % Find y indices covisibile with x.
    x_covis = covis(x,:);
    y_indices = find(x_covis);
    y_indices = y_indices(y_indices > x);
    
    if length(y_indices) < 2; continue; end
    
    % Calculate x-y vectors.
    x3d = poses(:, x);
    y_poses = poses(:, y_indices);
    dif3d = y_poses - repmat(x3d, 1, length(y_indices));
    
    % Filter non-covisible y pairs.
    yy_covis = covis(y_indices, y_indices);
    [rows, cols] = find(yy_covis);
    combs = [rows, cols];
    combs = combs(cols > rows, :);
    
    if ~any(yy_covis); continue; end
    
    % Calculate pairwise 3d angles.
    norms = sqrt(dif3d(1,:) .^ 2 + dif3d(2,:) .^ 2 + dif3d(3,:) .^ 2);
    a = norms(combs(:,1));
    b = norms(combs(:,2));
%     dif_dist = triu(dist(dif3d));
%     dif_dist = pdist(dif3d');
%     dif_dist = squareform(dif_dist);
%     c = dif_dist(sub2ind(size(dif_dist), combs(:,1), combs(:,2)))';
    c = point_dist(sub2ind(size(point_dist), y_indices(combs(:,1)), y_indices(combs(:,2))));
    x_angles = acos((a .^ 2 + b .^ 2 - c .^ 2) ./ (2 * a .* b));
    
    % Set 3d angles.
    angles3d{x} = sparse(y_indices(combs(:,1)), y_indices(combs(:,2)), x_angles, pcount, pcount);
end

end
