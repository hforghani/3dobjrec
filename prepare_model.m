clc; clearvars;
tic;
% You may run just once.
% run('VLFEATROOT/toolbox/vl_setup');
addpath daisy;

model_data_path = [get_dataset_path() '0-24(1)\0-24\anchiceratops\'];
% model_data_path = [get_dataset_path() '0-24(1)\0-24\ankylosaurus_brown\'];

prepared_model_fname = 'data/model_anchi_daisy_kd';
% prepared_model_fname = 'data/model_anchi_multi_kd';
% prepared_model_fname = 'data/model_anchiceratops_multi';
% prepared_model_fname = 'data/model_ankylosaurus_brown_multi';

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
    points = model.points;
    cal = model.calibration;
    [cam_desc, cam_desc_point_indexes] = cam.calc_multi_desc(points, cal, model_data_path);
    descriptors = [descriptors, cam_desc];
    desc_point_indexes = [desc_point_indexes, cam_desc_point_indexes];
end
kdtree = vl_kdtreebuild(double(descriptors));

model.descriptors = descriptors;
model.desc_point_indexes = desc_point_indexes;
model.kdtree = kdtree;
save (prepared_model_fname, 'model');

toc;
