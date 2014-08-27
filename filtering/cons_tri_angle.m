function cons = cons_tri_angle(model_corr, model_points, q_frames, model)

% start = tic;

ccount = size(model_corr, 2);
pcount = size(model_points, 2);
poses = model.get_poses();
matched_poses = poses(:, model_points(2,:));

covis = cons_covis3d(model_points, model.points, model_corr, true(ccount));

cons = Inf(ccount, ccount, ccount);

if isempty(covis)
    return;
end

corr_covis = covis(model_corr(2,:), model_corr(2,:));
max_dist = 0.1;
sigma = max_dist / 3;

for x = find(any(corr_covis))
    % Find y indices covisibile with x.
    x_covis = corr_covis(x,:);
    y_indices = find(x_covis);
    y_indices = y_indices(y_indices > x);
    
    if length(y_indices) < 2; continue; end
    
    % Calculate x-y vectors in 2d and 3d.
    x2d = q_frames(1:2, model_corr(1, x));
    x3d = matched_poses(:, model_corr(2, x));    
    poses2d = q_frames(1:2, model_corr(1, y_indices));
    poses3d = matched_poses(:, model_corr(2, y_indices));
    dif2d = poses2d - repmat(x2d, 1, length(y_indices));
    dif3d = poses3d - repmat(x3d, 1, length(y_indices));
    
    % Filter non-covisible y pairs.
    all_combs = nchoosek(1 : length(y_indices), 2);
    indices = sub2ind(size(corr_covis), y_indices(all_combs(:,1)), y_indices(all_combs(:,2)));
    y_covis = corr_covis(indices);
    combs = all_combs(y_covis, :);
    
    if ~any(y_covis); continue; end
    
    % Calculate pairwise 2d angles.
    angles2d = angle(dif2d(1,:) + dif2d(2,:) * 1i);
    dif_ang2d = pdist(angles2d');
    dif_ang2d(dif_ang2d > pi) = 2*pi - dif_ang2d(dif_ang2d > pi);
    dif_ang2d = dif_ang2d(y_covis);
    
    % Calculate pairwise 3d angles.
    norms = sqrt(dif3d(1,:) .^ 2 + dif3d(2,:) .^ 2 + dif3d(3,:) .^ 2);
    a = norms(combs(:,1));
    b = norms(combs(:,2));
    c = pdist(dif3d');
    c = c(y_covis);
    dif_ang3d = acos((a .^ 2 + b .^ 2 - c .^ 2) ./ (2 * a .* b));
    
    % Set distances between 2d and 3d angles.
    dist = abs(dif_ang3d - dif_ang2d);
    sub1 = ones(1,size(combs,1)) * x;
    cons_indices = sub2ind(size(cons), sub1, y_indices(combs(:,1)), y_indices(combs(:,2)));
    cons(cons_indices) = dist .* (dist < max_dist);

end

cons = exp(-.5 * (cons / sigma) .^ 2);

permu = perms([1 2 3]);
for j = 1 : length(permu)
    if ~all(permu(j,:) == [1 2 3])
        cons = max(cons, permute(cons, permu(j,:)));
    end
end

% fprintf('cons_tri_angle : %f\n', toc(start));

end
