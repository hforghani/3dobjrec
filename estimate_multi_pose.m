function [transforms, rec_indexes] = estimate_multi_pose(query_poses, points, model_indexes, correspondences, adj_matrices, models, obj_names, query_im_name)

SAMPLE_COUNT = 3;
ERROR_THRESH = 10;
MIN_INLIERS = 4;

image = imread(query_im_name);
global feat_fig proj_fig colors;
feat_fig = figure; imshow(image);
proj_fig = figure; imshow(image);
colors = {'r','g','b','c','m','y','k','w'};

transforms = {};
rec_indexes = [];

for i = 1 : length(correspondences)
    corr = correspondences{i};
    adj_mat = adj_matrices{i};
    corr_count = size(corr,2);

    model_i = model_indexes(i);
    fprintf('estimating pose of hyp %s ... ', obj_names{model_i});

    if size(corr, 2) < SAMPLE_COUNT
        fprintf('not enough points\n');
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
    figure(4); hold on;
    scatter(poses2d(1,:), poses2d(2,:), 'MarkerEdgeColor', colors{mod(i,length(colors))+1});

    model_f_name = ['data/model/' obj_names{model_i}];
    model = load(model_f_name);
    model = model.model;

    try
        [rotation_mat, translation_mat, inliers, final_err] = estimate_pose(poses2d, poses3d, adj_mat, model.calibration, SAMPLE_COUNT, ERROR_THRESH);
        if length(inliers) >= MIN_INLIERS
            show_results(poses2d, rotation_mat, translation_mat, inliers, model, i)
            transforms = [transforms; [rotation_mat, translation_mat]];
            rec_indexes = [rec_indexes; model_i];
            fprintf('successfuly done. Final error = %f\n', final_err);
        else
            fprintf('not enough inliers\n');
        end
    catch e
        if strcmp(e.message, 'ransac was unable to find a useful solution')
            fprintf('object not found\n');
        else
            disp(getReport(e,'extended'));
        end
    end
    clear model;
end




function show_results(matches2d, rotation_mat, translation_mat, inliers, model, index)

global feat_fig proj_fig colors;

% Draw inliers.
figure(feat_fig); hold on;
color = colors{mod(index,length(colors))+1};
scatter(matches2d(1,inliers), matches2d(2,inliers), 'filled', 'MarkerFaceColor', color);

% Map points with the found transformation.
points2d = model.project_to_img_plane(rotation_mat, translation_mat);
figure(proj_fig); hold on;
scatter(points2d(1,:), points2d(2,:), 5, 'filled', 'MarkerFaceColor', color);

