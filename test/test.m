close all; clearvars; clc;

addpath model daisy utils filtering estimation EPnP;
addpath PairwiseMatching;
addpath(genpath('RRWM'));

% You may run just once.
% run('VLFEATROOT/toolbox/vl_setup');

case_name = 'all10';

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
test_path = 'test_img/auto10/';
files = dir(test_path);
str_arr = {};
for i = 1:numel(files)
    name = files(i).name;
    if ~strcmp(name, '.') && ~strcmp(name, '..') && ~strcmp(name(end-2 : end), 'txt')
        str_arr = [str_arr, {files(i).name}];
    end
end


METHOD = 'gm'; % choices: gm, filter

% Set result file name.
parts = textscan(test_path, '%[^/]/%[^/]/');
folder_name = parts{end}{1};
cl = clock;
time_specifier = sprintf('%d-%d-%d-%d-%d', cl(1),cl(2),cl(3),cl(4),cl(5));
res_fname = sprintf('result/%s_%s_%s', time_specifier, folder_name, METHOD);
if exist('res_fname', 'file')
    load(res_fname, 'results');
else
    results = cell(length(str_arr), 1);
end

% Run the algorithm for all test images.
MIN_INDEX = 1;
MAX_INDEX = length(str_arr);

times = cell(MAX_INDEX, 1);
for i = MIN_INDEX : MAX_INDEX
    q_im_name = [test_path str_arr{i}];
    fprintf('========== testing %s ==========\n', q_im_name);
    [res, timing] = match_and_estimate(case_name, q_im_name, models, 'LoadMatches', true, 'LoadFiltered', false, 'Method', METHOD, 'Interactive', 0);
    times{i} = timing;
    results{i} = res;
    fprintf('========== done (elapsed time is %f sec.) ==========\n', timing.total); 
end
save(res_fname, 'results');


% Compute mean time.
matching_time = zeros(MAX_INDEX-MIN_INDEX,1);
filtering_time= zeros(MAX_INDEX-MIN_INDEX,1);
ransac_time = zeros(MAX_INDEX-MIN_INDEX,1);
for i = MIN_INDEX:MAX_INDEX
    matching_time(i) = times{i}.matching;
    filtering_time(i) = times{i}.filtering;
    ransac_time(i) = times{i}.ransac;
end
total = matching_time + filtering_time + ransac_time;
fprintf('========== MEAN TIME : %f + %f + %f = %f ==========\n', ...
    mean(matching_time), mean(filtering_time), mean(ransac_time), mean(total));

% Compute precision and recall.
gnd_truth = read_gnd_truth([test_path 'data.txt']);
test_result = read_test_result(res_fname);
[precision, recall] = compute_p_r(gnd_truth, test_result, false);
fprintf('========== RECALL = %f, PRECISION = %f ==========\n', recall, precision);

% Show results.
% show_test_result(test_path, models, obj_names, gnd_truth, test_result);
