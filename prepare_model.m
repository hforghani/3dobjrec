function prepare_model(obj_name, varargin)

read_nvm = true;
calc_descriptors = true;
if nargin > 1
    i = 1;
    while i <= length(varargin)
        if strcmp(varargin{i}, 'ReadNVM')
            read_nvm = varargin{i+1};
        elseif strcmp(varargin{i}, 'CalcDescriptors')
            calc_descriptors = varargin{i+1};
        end
        i = i + 2;
    end
end

tic;

model_data_path = [get_dataset_path() '0-24(1)\0-24\' obj_name '\'];

nvm_data_fname = ['data/model/' obj_name];
desc_data_fname = ['data/model_desc/' obj_name];


%%%%% Read nvm data.
if read_nvm
    model_fname = [model_data_path 'model.nvm'];
    model = read_model(model_fname);

    %%%%% Calculate point sizes.

    % Calculate scale of each measurement.
    fprintf('calculating scales ...\n');
    scales = [];
    for i = 1:length(model.cameras)
        fprintf('\tcamera %d ... ', i);
        cam_scales = model.cameras{i}.calc_scales(model.points, model.calibration, model_data_path);
        scales = [scales, cam_scales];
        fprintf('done\n');
    end

    fprintf('calculating sizes ... ');

    % Calculate transformed 3d pose of all points in each camera.
    transformed_points = zeros(length(model.cameras), length(model.points), 3);
    for i = 1:length(model.cameras)
        cam = model.cameras{i};
        points = model.trans_to_cam_coord(cam.rotation_matrix(), cam.center)';
        transformed_points(i, :, :) = points;
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
        nonzero = p_scales ~= 0;
        if sum(nonzero)
            point_sizes(i) = mean(p_scales(nonzero) .* p_depths(nonzero) ./ p_focal_len(nonzero));
        end
    end
    model.point_sizes = point_sizes;

    save (nvm_data_fname, 'model');
    
    fprintf('done\n');
    
else
    load(nvm_data_fname);
    disp('nvm data loaded\n');
end

%%%%% Calculate descriptors.
if calc_descriptors
    fprintf('calculating descriptors in %d cameras ...\n', length(model.cameras));
    descriptors = [];
    desc_point_indexes = [];
    for i = 1:length(model.cameras)
        cam = model.cameras{i};
        [cam_desc, cam_desc_point_indexes] = cam.calc_desc(model.points, model.calibration, model_data_path);
        descriptors = [descriptors, cam_desc];
        desc_point_indexes = [desc_point_indexes, cam_desc_point_indexes];
    end
    kdtree = vl_kdtreebuild(double(descriptors));

    % Model index of all descriptors is 1 as there is just one model.
    desc_model_indexes = ones(size(desc_point_indexes));
    obj_names = {obj_name};

    save (desc_data_fname, 'descriptors', 'desc_point_indexes', 'desc_model_indexes', 'kdtree', 'obj_names');
    
else
    % Load models if saved.
    load(desc_data_fname);
    disp('descriptors data loaded\n');
end

toc;

end