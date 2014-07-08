clearvars; close all; clc;

addpath model daisy utils EPnP PairwiseMatching;

% You may run just once.
% run('VLFEATROOT/toolbox/vl_setup');

case_name = 'all25';

% Load models.
fprintf('loading models ... ');
desc_model_f_name = ['data/model_desc/' case_name];
load(desc_model_f_name, 'obj_names');
obj_count = length(obj_names);
models = cell(obj_count, 1);
for i = 1:obj_count
    model_f_name = ['data/model/' obj_names{i}];
    load(model_f_name);
    models{i} = model;
end
fprintf('done\n');

% Fetch test image names.
test_path = 'test_img/auto/';
files = dir(test_path);
files = files(3:end);
str_arr = cell(numel(files), 1);
for i = 1:numel(files)
    if ~strcmp(files(i).name(end-2 : end), 'txt')
        str_arr{i} = files(i).name;
    else
        str_arr(i) = [];
    end
end

% Run the algorithm for all test images.
MIN_INDEX = 3;
MAX_INDEX = length(str_arr);
for i = MIN_INDEX : MAX_INDEX
    q_im_name = [test_path str_arr{i}];
    fprintf('========== testing %s ==========\n', q_im_name);
    match_and_estimate(case_name, q_im_name, models)
    fprintf('========== done ==========\n'); 
end
