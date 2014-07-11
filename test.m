clearvars; clc;

addpath model daisy utils EPnP PairwiseMatching;

% You may run just once.
% run('VLFEATROOT/toolbox/vl_setup');

case_name = 'all25';

% Load models.
fprintf('loading models ... ');
desc_model_f_name = ['data/model_desc/' case_name];
load(desc_model_f_name, 'obj_names');
objcount = length(obj_names);
models = cell(objcount, 1);
for i = 1:objcount
    model_f_name = ['data/model/' obj_names{i}];
    load(model_f_name);
    models{i} = model;
end
fprintf('done\n');

% Fetch test image names.
test_path = 'test_img/auto/';
files = dir(test_path);
str_arr = {};
for i = 1:numel(files)
    name = files(i).name;
    if ~strcmp(name, '.') && ~strcmp(name, '..') && ~strcmp(name(end-2 : end), 'txt')
        str_arr = [str_arr, {files(i).name}];
    end
end

% Run the algorithm for all test images.
MIN_INDEX = 19;
MAX_INDEX = 24;
for i = MIN_INDEX : MAX_INDEX
    q_im_name = [test_path str_arr{i}];
    fprintf('========== testing %s ==========\n', q_im_name);
    start = tic;
    match_and_estimate(case_name, q_im_name, models);
    time = toc - start;
    fprintf('========== done (elapsed time is %f) ==========\n', time); 
end

% Compute precision and recall.
test_data = read_test_data([test_path 'data.txt']);
test_result = read_test_result('result/', test_data);
[precision, recall] = compute_p_r(test_data, test_result);
fprintf('RECALL = %f, PRECISION = %f\n', recall, precision);
