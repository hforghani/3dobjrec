function [transforms, rec_indexes, inl_counts] = estimate_multi_pose(query_poses, points, ...
    model_indexes, correspondences, adj_matrices, models, obj_names, query_im_name, options, interactive)

SAMPLE_COUNT = 3;
ERROR_THRESH = 10;

if ~exist('interactive', 'var')
    interactive = 0;
end

global feat_fig proj_fig colors;

if interactive > 1
    image = imread(query_im_name);
    feat_fig = figure; imshow(image);
    proj_fig = figure; imshow(image);
    colors = {'r','g','b','c','m','y','k','w'};
end

transforms = {};
rec_indexes = [];
inl_counts = [];

for i = 1 : length(correspondences)
    corr = correspondences{i};
    adj_mat = adj_matrices{i};
    corr_count = size(corr,2);

    model_i = model_indexes(i);
    if interactive; fprintf('estimating pose of hyp %s ... ', obj_names{model_i}); end

    % Check if not enough correspondences.
    if size(corr, 2) < SAMPLE_COUNT
        if interactive; fprintf('not enough correspondences\n'); end
        continue;
    end
    
    % Check if not enough consistent correspondences when sampling guided by graph.
    if strcmp(options.sampling_mode, 'guidedRansac') && (...
            ( ...
                length(size(adj_mat)) == 2 && ...
                (nnz(adj_mat) < SAMPLE_COUNT * 2 || (SAMPLE_COUNT == 3 && nnz(adj_mat^2 & adj_mat) == 0))) ...
            || ...
                (length(size(adj_mat)) == 3 && nnz(adj_mat) < SAMPLE_COUNT * 6) ...
            )
        if interactive; fprintf('not enough consistent correspondences\n'); end
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
    if interactive > 1
        figure(feat_fig); hold on;
        scatter(poses2d(1,:), poses2d(2,:), 'MarkerEdgeColor', colors{mod(i,length(colors))+1});
    end

    model_f_name = ['data/model/' obj_names{model_i}];
    model = load(model_f_name);
    model = model.model;

    try
        [rotation_mat, translation_mat, inliers, final_err] = estimate_pose(poses2d, poses3d, adj_mat, model.calibration, SAMPLE_COUNT, ERROR_THRESH, options);
%         inlier_ratio = length(inliers) / size(poses2d, 2);
%         if interactive; fprintf('inliers/total : %d / %d = %f\n', length(inliers), size(poses2d, 2), inlier_ratio) end
        
%         if inlier_ratio < options.min_inl_ratio || length(inliers) < options.min_inl_count
%             if interactive; fprintf('not enough inliers\n'); end
%         else
        if interactive > 1
            show_results(poses2d, rotation_mat, translation_mat, inliers, model, i);
        end
        transforms = [transforms; [rotation_mat, translation_mat]];
        rec_indexes = [rec_indexes; model_i];
        inl_counts = [inl_counts; length(inliers)];
        if interactive; fprintf('successfuly done, final error = %f\n', final_err); end
%         end
    catch e
        if strcmp(e.message, 'ransac was unable to find a useful solution')
            if interactive; fprintf('object not found\n'); end
        else
            if interactive; disp(getReport(e,'extended')); end
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

