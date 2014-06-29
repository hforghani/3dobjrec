function [transforms, rec_indexes] = estimate_multi_pose(query_poses, points, correspondences, models, obj_names, query_im_name)

    SAMPLE_COUNT = 3;
    ERROR_THRESH = 8;
    MIN_INLIERS = 10;

    image = imread(query_im_name);
    figure(2);
    imshow(image);
    figure(3);
    imshow(image);
    h3 = figure(4);
    delete(h3);
    colors = {'r','g','b','c','m','y','k','w'};
    
    % Gather poses of all correspondences.
    corr_count = size(correspondences,2);
    poses2d = zeros(2, corr_count);
    poses3d = zeros(3, corr_count);
    for i = 1:corr_count
        poses2d(:,i) = query_poses(:,correspondences(1,i));
        point_index = correspondences(2,i);
        model_points = models{points(1,point_index)}.points;
        poses3d(:,i) = model_points{points(2,point_index)}.pos;
    end

    points_model_indexes = points(1,:);
    models_i = unique(points_model_indexes);
    model_count = length(models_i);
    transforms = {};
    rec_indexes = [];

    for i = 1 : model_count
        % Separate points and correspondences related to this model.
        model_i = models_i(i);
        model_indexes = find(points_model_indexes == model_i);
        is_of_model = ismember(correspondences(2,:), model_indexes);
        if ~any(is_of_model)
            continue;
        end
        
        fprintf('estimating pose of hyp %s ... ', obj_names{i});
        hyp_poses2d = poses2d(:, is_of_model);
        hyp_poses3d = poses3d(:, is_of_model);

        figure(2);
        hold on;
        scatter(hyp_poses2d(1,:), hyp_poses2d(2,:), 'MarkerEdgeColor', colors{mod(i,length(colors))+1});

        model_f_name = ['data/model/' obj_names{i}];
        model = load(model_f_name);
        model = model.model;

        if size(hyp_poses2d, 2) < SAMPLE_COUNT
            fprintf('not enough points\n');
            continue;
        end
        try
            [rotation_mat, translation_mat, inliers, final_err] = estimate_pose(hyp_poses2d, hyp_poses3d, model.calibration, SAMPLE_COUNT, ERROR_THRESH);
            if length(inliers) >= MIN_INLIERS
                show_results(hyp_poses2d, rotation_mat, translation_mat, inliers, model, model_i)
                transforms = [transforms; [rotation_mat, translation_mat]];
                rec_indexes = [rec_indexes; i];
                fprintf('successfuly done. Final error = %f\n', final_err);
            else
                fprintf('not enough inliers\n');
            end
        catch e
            if strcmp(e.message, 'ransac was unable to find a useful solution')
                fprintf('object not found\n');
            else
                disp(e);
                fprintf('%s\n', e.message);
            end
        end
        clear model;
    end


    function show_results(matches2d, rotation_mat, translation_mat, inliers, model, model_index)
        % Draw inliers.
        figure(2);
        hold on;
        scatter(matches2d(1,:), matches2d(2,:), 'MarkerEdgeColor', colors{mod(model_index,length(colors))+1});
        scatter(matches2d(1,inliers), matches2d(2,inliers), 'filled', 'MarkerFaceColor', colors{mod(model_index,length(colors))+1});

        % Map points with the found transformation.
        points2d = model.project_to_img_plane(rotation_mat, translation_mat);
        figure(3);
        hold on;
        scatter(points2d(1,:), points2d(2,:), 5, 'filled', 'MarkerFaceColor', colors{mod(model_index,length(colors))+1});
    end

end

