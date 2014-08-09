function cons = cons_tri_angle(model_corr, model_points, q_frames, model, min_toler, max_toler)

ccount = size(model_corr, 2);
combs = nchoosek(1:ccount, 3);
poses = model.get_poses();
matched_poses = poses(:, model_points(2,:));

covis = cons_covis3d(model_points, model.points, model_corr, true(ccount));

cons = zeros(ccount, ccount, ccount);
sigma = 0.2;

for i = 1 : size(combs,1)
    comb = combs(i, :);
    corr = model_corr(:, comb);
    p_indexes = corr(2,:);
    
    if covis(p_indexes(1), p_indexes(2)) && covis(p_indexes(2), p_indexes(3)) && covis(p_indexes(1), p_indexes(3)) ...
            && length(unique(p_indexes)) == 3 && length(unique(corr(1,:))) == 3
        poses3d = matched_poses(:, p_indexes);
        poses2d = q_frames(1:2, corr(1,:));

        x3d_h = [poses3d; ones(1,3)];
        x2d_h = [poses2d; ones(1,3)];
        K = model.calibration.get_calib_matrix();
        [R, T, ~, ~, ~] = efficient_pnp_gauss(x3d_h', x2d_h', K);
        dist = reprojection_error_usingRT(poses3d', poses2d', R, T, K);

%         theta3d = middle_angle(poses3d);
%         theta2d = middle_angle(poses2d);
% %         ratio = theta2d / theta3d;
%         dist = (theta2d - theta3d) / (theta2d + theta3d);

        if dist < 0.5
%         if dist < 0.1
            permu = perms(1:3);
            dist_gauss = exp(-.5 * (dist/sigma) .^ 2);
            for j = 1 : size(permu,1)
                cons(comb(permu(j,1)), comb(permu(j,2)), comb(permu(j,3))) = dist_gauss;
            end
        end
    end
end

end


function angle = middle_angle(poses)
    a = poses(:,2) - poses(:,1);
    b = poses(:,3) - poses(:,1);
    if size(poses,1) == 3
        angle = atan2(norm(cross(a,b)), dot(a,b));
    elseif size(poses,1) == 2
        angle = acos(dot(a,b) / (norm(a)*norm(b)));
    else
        angle = [];
    end
end
