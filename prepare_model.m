function prepare_model(obj_name)

clc;
tic;
% You may run just once.
% run('VLFEATROOT/toolbox/vl_setup');
addpath daisy;

model_data_path = [get_dataset_path() '0-24(1)\0-24\' obj_name '\'];

prepared_model_fname = ['data/model/' obj_name];
desc_model_fname = ['data/model_desc/' obj_name];


%% Read model
model_fname = [model_data_path 'model.nvm'];
model = read_model(model_fname);
save (prepared_model_fname, 'model');

%% Offline model preparation
fprintf('calculating descriptors in %d cameras ...\n', length(model.cameras));
descriptors = [];
desc_point_indexes = [];
for i = 1:length(model.cameras)
    cam = model.cameras{i};
    [cam_desc, cam_desc_point_indexes] = cam.calc_multi_desc(model.points, model.calibration, model_data_path);
    descriptors = [descriptors, cam_desc];
    desc_point_indexes = [desc_point_indexes, cam_desc_point_indexes];
end
kdtree = vl_kdtreebuild(double(descriptors));

% Model index of all descriptors is 1 as there is just one model.
desc_model_indexes = ones(size(desc_point_indexes));
obj_names = {obj_name};

save (desc_model_fname, 'descriptors', 'desc_point_indexes', 'desc_model_indexes', 'kdtree', 'obj_names');

toc;

end