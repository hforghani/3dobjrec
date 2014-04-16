clc; clearvars;

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
    tic;
    cam = model.cameras{i};
    points = model.points;
    cal = model.calibration;
    clear model;
    cam = cam.calc_multi_desc(points, cal, model_data_path);
    descriptors = [descriptors, cam.multiscale_desc];
    desc_point_indexes = [desc_point_indexes, cam.multi_desc_point_indexes];
    model_file = load(prepared_model_fname);
    model = model_file.model;
    model.cameras{i} = cam;
    save (prepared_model_fname, 'model');
    toc;
end

desc_kdtree = vl_kdtreebuild(double(descriptors));
save ('data/descriptors', 'descriptors');
save ('data/desc_point_indexes', 'desc_point_indexes');
save ('data/kdtree', 'desc_kdtree');
