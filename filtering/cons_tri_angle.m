function cons = cons_tri_angle(model_corr, model_points, q_frames, model)

% start = tic;

ccount = size(model_corr, 2);
pcount = size(model_points, 2);
poses = model.get_poses();
matched_poses = poses(:, model_points(2,:));

covis = cons_covis3d(model_points, model.points, model_corr, true(ccount));

cons = zeros(ccount, ccount, ccount);

if isempty(covis)
    return;
end

corr_covis = covis(model_corr(2,:), model_corr(2,:));
max_dist = 0.1;
sigma = max_dist / 2;

for x = find(any(corr_covis))
    x_covis = corr_covis(x,:);
    y_indices = find(x_covis);
    y_indices = y_indices(y_indices > x);
    
    for y = y_indices
        y_covis = corr_covis(y,:);
        z_indices = find(y_covis & x_covis);
        z_indices = z_indices(z_indices > y);
        
        for z = z_indices
            
            corr = model_corr(:, [x y z]);
            
            if length(unique(corr(1,:))) == 3
                poses3d = matched_poses(:, corr(2,:));
                poses2d = q_frames(1:2, corr(1,:));

                theta3d = middle_angle(poses3d);
                theta2d = middle_angle(poses2d);

                dist = theta2d - theta3d;
                if abs(dist) < max_dist
                    cons(x,y,z) = dist;
                end
            end
        end
    end
end

cons(cons~=0) = exp(-.5 * (cons(cons~=0) / sigma) .^ 2);

permu = perms([1 2 3]);
for i = 2 : length(permu)
    cons = max(cons, permute(cons, permu(i,:)));
end

% fprintf('cons_tri_angle : %f\n', toc(start));

end
