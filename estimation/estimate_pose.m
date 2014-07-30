function [rotation_mat, translation_mat, inliers, final_err] = estimate_pose(matches2d, matches3d, adj_mat, calibration, sample_count, threshold, varargin)

sampling_mode = 'regular';

if nargin > 6
    k = 1;
    while k <= length(varargin)
        if strcmp(varargin{k}, 'SamplingMode')
            sampling_mode = varargin{k+1};
        end
        k = k + 2;
    end
end

K = calibration.get_calib_matrix(); % calibration matrix
corr_data = [matches2d; matches3d];

% Run P3P with RANSAC.
switch sampling_mode
    case 'graph'
        [M, inliers] = ransac_graph_samp(corr_data, adj_mat, @epnp_fittingfn, @epnp_distfn, @degenfn , sample_count, threshold, 0, 100, 50);
    case 'regular'
        [M, inliers] = ransac(corr_data, @epnp_fittingfn, @epnp_distfn, @degenfn , sample_count, threshold, 0, 100, 50);
end

rotation_mat = M(:,1:3);
translation_mat = M(:,4);
final_err = reprojection_error_usingRT(matches3d(:,inliers)', matches2d(:,inliers)', rotation_mat, translation_mat, K);

function M = epnp_fittingfn(data)
% Estimate camera position by EPnP.
    count = size(data, 2);
    x3d_h = [data(3:5,:); ones(1,count)];
    x2d_h = [data(1:2,:); ones(1,count)];
    [R, T, ~, ~, ~] = efficient_pnp_gauss(x3d_h', x2d_h', K);
    M = [R, T];
end

function [inliers, M] = epnp_distfn(M, data, t)
% Get best camera position with maximum number of inliers.
    if isempty(M)
        inliers = [];
        return;
    end
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
% degeneration function
    r = 0;
end

end


