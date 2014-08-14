function [results, times] = test(case_name, test_path, local_method, global_method, ...
    load_matches, load_filtered, min_index, max_index, interactive)

% interactive:      0 for no ouput; 1 for just precision, recal, and
%                   timing; 2 logs details in addition; 3 shows images too.

if interactive; fprintf('======= testing %s, local: %s, global: %s =======\n', case_name, local_method, global_method); end

close all;

addpath test model utils filtering estimation;
addpath lib/daisy/ lib/EPnP/ lib/PairwiseMatching/ lib/medoidshift/;
addpath(genpath('lib/RRWM/'));

% You may run just once.
% run('lib/VLFEAT/toolbox/vl_setup');

% Load models.
if interactive > 1; fprintf('loading models ... '); end
desc_model_f_name = ['data/model_desc/' case_name];
load(desc_model_f_name, 'obj_names');
objcount = length(obj_names);
models = cell(objcount, 1);
for i = 1:objcount
    model_f_name = ['data/model/' obj_names{i}];
    load(model_f_name);
    models{i} = model;
end
clear model; % to save memory
if interactive > 1; fprintf('done\n'); end

% Fetch test image names.
files = dir(test_path);
str_arr = {};
for i = 1:numel(files)
    name = files(i).name;
    if ~strcmp(name, '.') && ~strcmp(name, '..') && ~strcmp(name(end-2 : end), 'txt')
        str_arr = [str_arr, {files(i).name}];
    end
end


% Run the algorithm for all test images.

results = cell(length(str_arr), 1);
times = cell(max_index, 1);

for i = min_index : max_index
    q_im_name = [test_path str_arr{i}];
    if interactive > 1; fprintf('======= testing %s, local: %s, global: %s =======\n', q_im_name, local_method, global_method); end
    [res, timing] = match_and_estimate(case_name, q_im_name, models, 'LoadMatches', ...
        load_matches, 'LoadFiltered', load_filtered, 'Local', local_method, 'Global', ...
        global_method, 'Interactive', interactive - 1);
    times{i} = timing;
    results{i} = res;
    if interactive > 1; fprintf('======= done (elapsed time is %f sec.) =======\n', timing.total); end
end

% Save results.
parts = textscan(test_path, '%[^/]/%[^/]/');
folder_name = parts{end}{1};
cl = clock;
time_specifier = sprintf('%d-%d-%d-%d-%d', cl(1),cl(2),cl(3),cl(4),cl(5));
res_fname = sprintf('result/%s_%s_%s_%s', time_specifier, folder_name, local_method, global_method);
save(res_fname, 'results', 'times');


if interactive
    
    % Compute mean time.
    matching_time = zeros(max_index-min_index+1,1);
    filtering_time= zeros(max_index-min_index+1,1);
    ransac_time = zeros(max_index-min_index+1,1);
    for i = min_index:max_index
        matching_time(i) = times{i}.matching;
        filtering_time(i) = times{i}.filtering;
        ransac_time(i) = times{i}.ransac;
    end
    total = matching_time + filtering_time + ransac_time;
    fprintf('======= MEAN TIME : %f + %f + %f = %f =======\n', ...
        mean(matching_time), mean(filtering_time), mean(ransac_time), mean(total));

    % Compute precision and recall.
    gnd_truth = read_gnd_truth([test_path 'data.txt'], min_index, max_index);
    test_result = read_test_result(res_fname);
    [precision, recall] = compute_p_r(gnd_truth, test_result, false);
    fprintf('======= RECALL = %f, PRECISION = %f =======\n', recall, precision);

    % Show results.
    if interactive > 2
        show_test_result(test_path, models, obj_names, gnd_truth, test_result);
    end
end
