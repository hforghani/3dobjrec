function matches = match_2d_to_3d(I, model)
% Match 2d features of I with 3d features of model.

%%Extract features.
query_im = single(rgb2gray(I));
[sift_frames, sift_descriptors] = vl_sift(query_im);

%% Display features.
figure;
imshow(I);
hold on;

perm = randperm(size(sift_frames,2));
sel = perm(1:500);
h1 = vl_plotframe(sift_frames(:,sel));
h2 = vl_plotframe(sift_frames(:,sel));
set(h1,'color','k','linewidth',3);
set(h2,'color','y','linewidth',2);

points_num = length(model.points);
max_error = 1;

% Iterate on query image key points.
for feature_index = 1:size(sift_frames, 2)
    query_f = sift_frames(:,feature_index);
    query_meas = Measurement();
    point_pos = query_f(1:2,1);
    multiscale_des = query_meas.calc_desc_in_scales(query_im, point_pos);
    fprintf('%i : query point (%f, %f):\n', feature_index, point_pos(1), point_pos(2));

    % Iterate on points.
    for point_index = 1:points_num
        pt = model.points{point_index};
        fprintf('%i : model point (%f, %f, %f) : ', point_index, pt.pos(1), pt.pos(2), pt.pos(3));

        % Iterate on 3d point measurements.
        for measure_i = 1:pt.measure_num
            meas = pt.measurements{measure_i};
            [f, d, dist] = meas.multiscale_desc.get_best_match(multiscale_des.multiscale_desc);
            
            fprintf('%i:%f, ', meas.image_index, dist);
            if dist < max_error
                fprintf('\n====== Matched: (%d, %d) to (%d, %d, %d) ======\n', ...
                    query_f(1), query_f(2), pt.pos(1), pt.pos(2), pt.pos(3));
            end
        end
        fprintf('\n');
    end
end

matches = [];
