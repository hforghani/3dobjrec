function [transforms, rec_indexes] = estimate_multi_pose(query_poses, points, model_indexes, correspondences, adj_matrices, models, obj_names, query_im_name, varargin)

SAMPLE_COUNT = 3;
ERROR_THRESH = 10;

min_inl_ratio = 0;
min_inl_count = 0;
sampling_mode = 'guidedRansac';
interactive = false;

if nargin > 8
    i = 1;
    while i <= length(varargin)
        if strcmp(varargin{i}, 'MinInlierRatio')
            min_inl_ratio = varargin{i+1};
        elseif strcmp(varargin{i}, 'MinInlierCount')
            min_inl_count = varargin{i+1};
        elseif strcmp(varargin{i}, 'SamplingMode')
            sampling_mode = varargin{i+1};
        elseif strcmp(varargin{i}, 'Interactive')
            interactive = varargin{i+1};
        end
        i = i + 2;
    end
end

if interactive
    image = imread(query_im_name);
    global feat_fig proj_fig colors;
    feat_fig = figure; imshow(image);
    proj_fig = figure; imshow(image);
    colors = {'r','g','b','c','m','y','k','w'};
end

transforms = {};
rec_indexes = [];

for i = 1 : length(correspondences)
    corr = correspondences{i};
    adj_mat = adj_matrices{i};
    corr_count = size(corr,2);

    model_i = model_indexes(i);
    fprintf('estimating pose of hyp %s ... ', obj_names{model_i});

    % Check if not enough correspondences.
    if size(corr, 2) < SAMPLE_COUNT
        fprintf('not enough correspondences\n');
        continue;
    end
    
    % Check if not enough consistent correspondences when sampling guided by graph.
    if strcmp(sampling_mode, 'guidedRansac') && (...
            ( ...
                length(size(adj_mat)) == 2 && ...
                (nnz(adj_mat) < SAMPLE_COUNT * 2 || (SAMPLE_COUNT == 3 && nnz(adj_mat^2 & adj_mat) == 0))) ...
            || ...
                (length(size(adj_mat)) == 3 && nnz(adj_mat) < SAMPLE_COUNT * 6) ...
            )
        fprintf('not enough consistent correspondences\n');
        continue;
    end

    % Gather poses of all correspondences.
    poses2d = zeros(2, corr_count);
    poses3d = zeros(3, corr_count);
    for j = 1:corr_count
        poses2d(:,j) = query_poses(:,corr(1,j));
        point_index = corr(2,j);
        model_points = models{points(1,point_index)}.points;
        poses3d(:,j) = model_points{points(2,point_index)}.pos;
    end
    
%     Show all hypothesis 2d poses.
    if interactive
        figure(feat_fig); hold on;
        scatter(poses2d(1,:), poses2d(2,:), 'MarkerEdgeColor', colors{mod(i,length(colors))+1});
    end

    model_f_name = ['data/model/' obj_names{model_i}];
    model = load(model_f_name);
    model = model.model;

    try
        [rotation_mat, translation_mat, inliers, final_err] = estimate_pose(poses2d, poses3d, adj_mat, model.calibration, SAMPLE_COUNT, ERROR_THRESH, 'SamplingMode', sampling_mode);
        inlier_ratio = length(inliers) / size(poses2d, 2);
%         fprintf('inliers/total : %d / %d = %f\n', length(inliers), size(poses2d, 2), inlier_ratio)
        
        if inlier_ratio < min_inl_ratio || length(inliers) < min_inl_count
            fprintf('not enough inliers\n');
        else
            if interactive
                show_results(poses2d, rotation_mat, translation_mat, inliers, model, i);
            end
            transforms = [transforms; [rotation_mat, translation_mat]];
            rec_indexes = [rec_indexes; model_i];
            fprintf('successfuly done, final error = %f\n', final_err);
        end
    catch e
        if strcmp(e.message, 'ransac was unable to find a useful solution')
            fprintf('object not found\n');
        else
            disp(getReport(e,'extended'));
        end
    end
    
end




function show_results(matches2d, rotation_mat, translation_mat, inliers, model, index)

global feat_fig proj_fig colors;
color = colors{mod(index,length(colors))+1};

% Draw inliers.
figure(feat_fig); hold on;
scatter(matches2d(1,inliers), matches2d(2,inliers), 'filled', 'MarkerFaceColor', color);

% Map points with the found transformation.
points2d = model.project_to_img_plane(rotation_mat, translation_mat);
figure(proj_fig); hold on;
scatter(points2d(1,:), points2d(2,:), 5, 'filled', 'MarkerFaceColor', color);

