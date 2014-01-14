function matches = match_2d_to_3d(I, model, model_path)
% Match 2d features of I with 3d features of model.

%%Extract features.
gray = single(rgb2gray(I));
[sift_frames, sift_descriptors] = vl_sift(gray);

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
    query_d = sift_descriptors(:,feature_index);
    fprintf('%i : query point (%f, %f):\n', feature_index, query_f(1), query_f(2));

    % Iterate on points.
    for point_index = 1:points_num
        pt = model.points{point_index};
        fprintf('%i : model point (%f, %f, %f) : ', point_index, pt.pos(1), pt.pos(2), pt.pos(3));

        % Iterate on 3d point measurements.
        for measure_i = 1:pt.measure_num
            measurement = pt.measurements{measure_i};
            image_index = measurement.image_index;    
            file_name = model.cameras{image_index}.file_name;
            camera_image = imread([model_path 'db_img\' file_name]);

            cal = model.calibration;
            Kc = [1 0 cal.cx; 0 cal.fy/cal.fx cal.cy; 0 0 1];
            point = Kc * [measurement.pos; 1];
            
            % TODO: do vl_sift once for all frames.
            camera_gray = single(rgb2gray(camera_image));
            frames = [point(1:2); query_f(3:4)];
            [camera_f, camera_d] = vl_sift(camera_gray, 'frames', frames);

            dist = norm(double(camera_d - query_d));
            fprintf('%i:%f, ', measurement.image_index, dist);
            if dist < max_error
                fprintf('\n====== Matched: (%d, %d) to (%d, %d, %d) ======\n', ...
                    query_f(1), query_f(2), pt.pos(1), pt.pos(2), pt.pos(3));
            end
            %{
            imshow(camera_image);
            hold on;
            scatter(calibration.cx, calibration.cy, 100 , 'r+');
            scatter(point(1), point(2), 100 , 'y');
            %}
        end
        fprintf('\n');
    end
end


matches = [];
