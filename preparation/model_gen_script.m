clearvars; clc;

% You may run just once.
% run('lib/VLFEAT/toolbox/vl_setup');
addpath lib/daisy;
addpath model;
addpath utils;

base_path = get_dataset_path();
folders = dir(base_path);
folders = folders(3:end);

start_i = 22;
% end_i = length(folders);
end_i = 50;
for i = start_i:end_i
    obj_name = folders(i).name;
    fprintf('preparing model "%s"\n', obj_name);
    prepare_model(obj_name, base_path, 'ReadNVM', false, 'CalcDescriptors', false, 'CalcPointSizes', true);
end
