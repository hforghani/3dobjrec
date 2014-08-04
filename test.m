close all; clearvars; clc;

addpath test model utils filtering estimation;
addpath lib/daisy lib/EPnP lib/PairwiseMatching;
addpath(genpath('lib/RRWM'));

% You may run just once.
% run('lib/VLFEAT/toolbox/vl_setup');


% Set parameters.
CASE_NAME = 'all50';
TEST_PATH = 'test_img/auto50/';
METHOD = 'gm'; % choices: gm, filter
LOAD_MATCHES = true;
LOAD_FILTERED = false;
MIN_INDEX = 1;
MAX_INDEX = 30;


% Load models.
fprintf('loading models ... ');
desc_model_f_name = ['data/model_desc/' CASE_NAME];
load(desc_model_f_name, 'obj_names');
objcount = length(obj_names);
models = cell(objcount, 1);
for i = 1:objcount
    model_f_name = ['data/model/' obj_names{i}];
    load(model_f_name);
    models{i} = model;
end
clear model; % to save memory
fprintf('done\n');

% Fetch test image names.
files = dir(TEST_PATH);
str_arr = {};
for i = 1:numel(files)
    name = files(i).name;
    if ~strcmp(name, '.') && ~strcmp(name, '..') && ~strcmp(name(end-2 : end), 'txt')
        str_arr = [str_arr, {files(i).name}];
    end
end


% Run the algorithm for all test images.

results = cell(length(str_arr), 1);
times = cell(MAX_INDEX, 1);

for i = MIN_INDEX : MAX_INDEX
    q_im_name = [TEST_PATH str_arr{i}];
    fprintf('========== testing %s ==========\n', q_im_name);
    [res, timing] = match_and_estimate(CASE_NAME, q_im_name, models, 'LoadMatches', LOAD_MATCHES, 'LoadFiltered', LOAD_FILTERED, 'Method', METHOD, 'Interactive', 0);
    times{i} = timing;
    results{i} = res;
    fprintf('========== done (elapsed time is %f sec.) ==========\n', timing.total); 
end

% Save results.
parts = textscan(TEST_PATH, '%[^/]/%[^/]/');
folder_name = parts{end}{1};
cl = clock;
time_specifier = sprintf('%d-%d-%d-%d-%d', cl(1),cl(2),cl(3),cl(4),cl(5));
res_fname = sprintf('result/%s_%s_%s', time_specifier, folder_name, METHOD);
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
gnd_truth = read_gnd_truth([TEST_PATH 'data.txt']);
test_result = read_test_result(res_fname);
[precision, recall] = compute_p_r(gnd_truth, test_result, false);
fprintf('========== RECALL = %f, PRECISION = %f ==========\n', recall, precision);

% Show results.
% show_test_result(test_path, models, obj_names, gnd_truth, test_result);
