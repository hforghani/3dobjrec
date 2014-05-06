function [rotation_mat, translation_mat, inliers, final_err] = estimate_pose(matches2d, matches3d, model, sample_count, threshold)

%% Run P3P with RANSAC.
addpath EPnP;

K = model.get_calib_matrix(); % calibration matrix

corr_data = [matches2d; matches3d];

[M, inliers] = ransac(corr_data, @epnp_fittingfn, @epnp_distfn, @degenfn , sample_count, threshold);
rotation_mat = M(:,1:3);
translation_mat = M(:,4);
final_err = reprojection_error_usingRT(matches3d(:,inliers)', matches2d(:,inliers)', rotation_mat, translation_mat, K);

function M = epnp_fittingfn(data)
%% Estimate camera position by EPnP.
    count = size(data, 2);
    x3d_h = [data(3:5,:); ones(1,count)];
    x2d_h = [data(1:2,:); ones(1,count)];
    [R, T, ~, ~, ~] = efficient_pnp_gauss(x3d_h', x2d_h', K);
    M = [R, T];
end

function [inliers, M] = epnp_distfn(M, data, t)
%% Get best camera position with maximum number of inliers.
    if ~iscell(M)
        M = {M};
    end
    max_inliers = -1;
    for i = 1:length(M)
        cur_M = M{i};
        R = cur_M(:,1:3);
        T = cur_M(:,4);
        data_count = size(data,2);
        errors = zeros(data_count,1);
        
        for j = 1:data_count
            x = data(:,j);
            point3d = x(3:5);
            point2d = x(1:2);
            error = reprojection_error_usingRT(point3d', point2d', R, T, K);
            errors(j) = error;
        end

        cur_inliers = find(errors < t);
        if length(cur_inliers) > max_inliers
            max_inliers = length(cur_inliers);
            inliers = cur_inliers;
            best_model = cur_M;
        end
    end
    M = best_model;
end

function r = degenfn(data)
%% degeneration function
    r = 0;
end

end


