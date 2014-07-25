clearvars; clc;

% You may run just once.
% run('VLFEATROOT/toolbox/vl_setup');
addpath daisy;
addpath model;
addpath utils;

base_path = [get_dataset_path() '0-24(1)\0-24\'];
folders = dir(base_path);
folders = folders(3:end);

start_i = 1;
end_i = length(folders);
% end_i = 10;
for i = start_i:end_i
    obj_name = folders(i).name;
    fprintf('preparing model "%s"\n', obj_name);
    prepare_model(obj_name, 'ReadNVM', true, 'CalcDescriptors', true);    
end
