function [adj_mat, cons_score] = cons_pairwise_geo(model_corr, model_points, q_frames, model, adj_mat, min_toler, max_toler)
% adj_mat:      C*C adjucecny matrix of pairwise geometrically consistent
%               correspondences.
% cons_score:   C*C matrix of consistency of estimated pose distances and
%               real pose distances.
    
    % Estimate pose of points in the query camera.
    corr_count = size(model_corr, 2);
    point_poses = model.get_poses();
    point_poses = point_poses(:, model_points(2, model_corr(2, :)));
    sizes = model.point_sizes(model_points(2, model_corr(2, :)));
    scales = q_frames(3, model_corr(1, :));
    est_poses = zeros(3, corr_count);
    f = model.calibration.fx; % Focal length
    image_coord_poses = [q_frames(1:2,model_corr(1, :));
                        ones(1,corr_count) * f];
    nonzero = sizes ~= 0;
    est_poses(:,nonzero) = repmat((sizes(nonzero) ./ scales(nonzero)), 3, 1) ...
                        .* image_coord_poses(:, nonzero);
    
    ratios = zeros(corr_count);
    cons_score = zeros(corr_count);
    
    % Compute consistency of estimated poses and real poses for all pairs.
    for i = 1 : corr_count-1
        for j = i+1 : corr_count
            if adj_mat(i,j) && any(est_poses(:,i) ~= 0) && any(est_poses(:,j) ~= 0)
                est_dist = norm(est_poses(:,i) - est_poses(:,j));
                real_dist = norm(point_poses(:,i) - point_poses(:,j));
                ratios(i,j) = est_dist / real_dist;
                cons_score(i,j) = (est_dist - real_dist) / (est_dist + real_dist); % Gaussian function is applied in the next lines. Values of cons_score are in range [0,1].
            end
        end
    end
    
    % Make symmetric and apply thresholds.
    ratios = ratios + ratios';
    adj_mat = adj_mat & ratios > min_toler & ratios < max_toler;
    
    % Apply gaussian on consistency scores.
    sigma = 0.2;
    cons_score = cons_score + cons_score';
    cons_score = exp(-.5 * (cons_score/sigma) .^ 2);
    cons_score(logical(eye(corr_count))) = 0;
end
