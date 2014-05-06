function transforms = estimate_multi_pose(matches2d, matches3d, match_model_indexes, obj_names, query_im_name)

start_sample_count = 5;
error_threshold = 30;

image = imread(query_im_name);
figure(1);
imshow(image);
figure(2);
imshow(image);
h3 = figure(3);
delete(h3);

models = unique(match_model_indexes);
model_count = length(models);
transforms = cell(model_count, 1);

for i = 1 : model_count
    fprintf('estimating pose of hyp %d ...\n', i);
    model_index = models(i);
    model_indexes = match_model_indexes == model_index;
    hyp_matches2d = matches2d(:, model_indexes);
    hyp_matches3d = matches3d(:, model_indexes);
    
    figure(1);
    hold on;
    scatter(hyp_matches2d(1,:), hyp_matches2d(2,:), 30, ones(size(hyp_matches2d,2), 1)*100 *  model_index);

    model_f_name = ['data/model_' obj_names{i}];
    load(model_f_name);

    s = start_sample_count;
    exp_thrown = 1;
    while exp_thrown && s < 15
        if size(hyp_matches2d, 2) < s
            fprintf('s=%d : not enough points\n', s);
            break;
        end
        try
            [rotation_mat, translation_mat, inliers, final_err] = estimate_pose(hyp_matches2d, hyp_matches3d, model, s, error_threshold);
            show_results(hyp_matches2d, rotation_mat, translation_mat, inliers, model, model_index)
            transforms{i} = [rotation_mat, translation_mat];
            exp_thrown = 0;
            fprintf('s=%d : successfuly done\n', s);
            fprintf('Final error = %f\n\n', final_err);
            break;
        catch e
            fprintf('s=%d : %s\n', s, e.message);
            s = s + 1;
        end
    end
    clear model;
    if exp_thrown
        fprintf('object not found\n\n');
    end
end

end


function show_results(matches2d, rotation_mat, translation_mat, inliers, model, model_index)
    % Draw inliers.
    figure(1);
    hold on;
    scatter(matches2d(1,:), matches2d(2,:), 30, ones(size(matches2d,2), 1)*100 *  model_index);
    scatter(matches2d(1,inliers), matches2d(2,inliers), 30, ones(size(inliers))*100 *  model_index, 'filled');

    % Map points with the found transformation.
    points2d = model.project_points(rotation_mat, translation_mat);
    figure(2);
    hold on;
    scatter(points2d(1,:), points2d(2,:), 10, ones(size(points2d,2), 1)*100 * model_index, 'filled');

    points3d = model.transform_points(rotation_mat, translation_mat);
    figure(3);
    hold on;
    scatter3(points3d(1,:), points3d(2,:), points3d(3,:), 5, ones(size(points2d,2), 1)*100 * model_index, 'filled');
end
