function [results, times] = test(case_name, test_path, load_matches, load_filtered, min_index, max_index, interactive, options)

% interactive:      0 for no ouput; 1 for just precision, recal, and
%                   timing; 2 logs details in addition; 3 shows images too.
% options.local:    local filter method. choices: hao, gradient, sm, ipfp, rrwm
% options.global:   global filter method. choices: hao, geom, geomGradient,
%                   geomSM, geomIPFP, geomRRWM, angle

if nargin < 8
    options = [];
end
if ~isfield(options, 'local'); options.local = 'gradient'; end
if ~isfield(options, 'global'); options.global = 'gradient'; end
if ~isfield(options, 'min_inl_count'); options.min_inl_count = 0; end
if ~isfield(options, 'min_inl_ratio'); options.min_inl_ratio = 0; end
if ~isfield(options, 'scale_factor'); options.scale_factor = 8; end
if ~isfield(options, 'sigma_mult_2d'); options.sigma_mult_2d = 1; end
if ~isfield(options, 'nei_ratio_3d'); options.nei_ratio_3d = 0.05; end
if ~isfield(options, 'sigma_mult_3d'); options.sigma_mult_3d = 0.5; end
if ~isfield(options, 'top_hyp_num'); options.top_hyp_num = 5; end
if ~isfield(options, 'sampling_mode'); options.sampling_mode = 'guidedRansac'; end

if interactive; fprintf('======= testing %s, local: %s, global: %s =======\n', case_name, options.local, options.global); end

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
    if interactive > 1; fprintf('======= testing %s =======\n', q_im_name); end
    [res, timing] = match_and_estimate(case_name, q_im_name, models, options, 'LoadMatches', ...
        load_matches, 'LoadFiltered', load_filtered, 'Interactive', interactive - 1);
    times{i} = timing;
    results{i} = res;
    if interactive > 1; fprintf('======= done (elapsed time is %f sec.) =======\n', timing.total); end
end

% Save results.
parts = textscan(test_path, '%[^/]/%[^/]/');
folder_name = parts{end}{1};
cl = clock;
time_specifier = sprintf('%d-%d-%d-%d-%d', cl(1),cl(2),cl(3),cl(4),cl(5));
res_fname = sprintf('result/%s_%s_%s_%s', time_specifier, folder_name, options.local, options.global);
save(res_fname, 'results', 'times');


if interactive
    analyse_results(results, times, min_index, max_index, test_path);
end

% Show results.
if interactive > 2
    show_test_result(test_path, models, obj_names, gnd_truth, test_result);
end
