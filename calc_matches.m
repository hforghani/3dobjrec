function calc_matches(model_f_name, query_im_name, matches_f_name)

    % You may run just once.
    % run('VLFEATROOT/toolbox/vl_setup');

    model_file = load(model_f_name);
    model = model_file.model;
    image = imread(query_im_name);

    %% Match 2d-to-3d
    edge_thresh = 100;
    [matches2d, matches3d, matches_dist] = match_2d_to_3d(image, model, matches_f_name, edge_thresh);

    save(matches_f_name, 'matches2d', 'matches3d', 'matches_dist');

%     figure;
%     imshow(image);
%     hold on;
%     scatter(matches2d(1,:), matches2d(2,:), 'r', 'filled');

end
