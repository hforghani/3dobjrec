function prepare_model(obj_name)

tic;

model_data_path = [get_dataset_path() '0-24(1)\0-24\' obj_name '\'];

simple_model_fname = ['data/model/' obj_name];
desc_model_fname = ['data/model_desc/' obj_name];


% %% Read model
% model_fname = [model_data_path 'model.nvm'];
% model = read_model(model_fname);
% 
% %% Calculating descriptors
% fprintf('calculating descriptors in %d cameras ...\n', length(model.cameras));
% descriptors = [];
% desc_point_indexes = [];
% scales = [];
% for i = 1:length(model.cameras)
%     cam = model.cameras{i};
%     [cam_desc, cam_desc_point_indexes] = cam.calc_desc(model.points, model.calibration, model_data_path);
%     descriptors = [descriptors, cam_desc];
%     desc_point_indexes = [desc_point_indexes, cam_desc_point_indexes];
%     scales = [scales, cam_scales];
% end
% kdtree = vl_kdtreebuild(double(descriptors));
% 
% % Model index of all descriptors is 1 as there is just one model.
% desc_model_indexes = ones(size(desc_point_indexes));
% obj_names = {obj_name};

%% Load models if saved.
load(simple_model_fname);
load(desc_model_fname);

%% Calculate scale of each measurement.
fprintf('calculating scales ...\n');
scales = [];
for i = 1:length(model.cameras)
    fprintf('\tcamera %d ... ', i);
    cam_scales = model.cameras{i}.calc_scales(model.points, model.calibration, model_data_path);
    scales = [scales, cam_scales];
    fprintf('done\n');
end

%% Calculate point sizes.
fprintf('calculating sizes ... ');

% Calculate transformed 3d pose of all points in each camera.
transformed_points = zeros(length(model.cameras), length(model.points), 3);
for i = 1:length(model.cameras)
    cam = model.cameras{i};
    transformed_points(i, :, :) = model.trans_to_cam_coord(cam.rotation_matrix(), cam.center)';
end

% Calculate size of each point.
point_sizes = zeros(1, length(model.points));
for i = 1:length(model.points)
    p = model.points{i};
    meas_num = p.measure_num;
    p_scales = scales(desc_point_indexes == i);
    p_depths = zeros(1, meas_num);
    p_focal_len = zeros(1, meas_num);
    for j = 1:meas_num
        cam_index = p.measurements{j}.image_index;
        p_depths(j) = transformed_points(cam_index, i, 3);
        p_focal_len(j) = model.cameras{cam_index}.focal_length;
    end
    valid = p_scales ~= 0;
    if sum(valid)
        point_sizes(i) = mean(p_scales(valid) .* p_depths(valid) ./ p_focal_len(valid));
    end
end
model.point_sizes = point_sizes;
fprintf('done\n');

%% Save variables.
fprintf('saving ... ');
save (simple_model_fname, 'model');
save (desc_model_fname, 'descriptors', 'desc_point_indexes', 'desc_model_indexes', 'kdtree', 'obj_names');
fprintf('done\n');

toc;

end