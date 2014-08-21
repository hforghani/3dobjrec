function [results, timing] = match_and_estimate(case_name, query_im_name, models, options, varargin)

load_match = false;
load_fil_match = false;
interactive = 0;

% Check parameter arguments.
if nargin > 3
    i = 1;
    while i <= length(varargin)
        if strcmp(varargin{i}, 'LoadMatches')
            load_match = varargin{i+1};
        elseif strcmp(varargin{i}, 'LoadFiltered')
            load_fil_match = varargin{i+1};
        elseif strcmp(varargin{i}, 'Interactive')
            interactive = varargin{i+1};
        end
        i = i + 2;
    end
end

% Initialize.
parts = textscan(query_im_name, '%s', 'delimiter', '/');
parts = textscan([parts{1}{end-1} '_' parts{1}{end}], '%s', 'delimiter', '.');
exact_name = parts{1}{1};
matches_f_name = sprintf('data/matches/%s_%s', case_name, exact_name);
fil_match_f_name = sprintf('data/matches/%s_%s_%s_%s', case_name, exact_name, options.local, options.global);
desc_model_f_name = sprintf('data/model_desc/%s', case_name);
load(desc_model_f_name, 'obj_names');

timing = struct('matching', 0, 'filtering', 0, 'ransac', 0);

% Match 2d to 3d
if ~load_match
    image = imread(query_im_name);
    desc_model = load(desc_model_f_name);
    start = tic;
    [query_frames, correspondences, points, corr_dist] = match_2d_to_3d(image, desc_model, models);
    timing.matching = toc(start);
    clear desc_model; % to save memory.
    save(matches_f_name, 'query_frames', 'points', 'correspondences', 'corr_dist');
else
    load(matches_f_name);
    if interactive; fprintf('matches loaded\n'); end
end

% Filter correspondences.
if ~load_fil_match
    if interactive; fprintf('filtering correspondences ...\n'); end
    start = tic;
    if strcmp(options.local, 'hao') && strcmp(options.global, 'hao')
        [sel_model_i, sel_corr, sel_adj_mat] = ...
            filter_corr(query_frames, points, correspondences, models, obj_names, ...
            query_im_name, options, interactive);
    else
        [sel_model_i, sel_corr, sel_adj_mat] = ...
            graph_match_corr(query_frames, points, correspondences, corr_dist, ...
            models, obj_names, query_im_name, options, interactive);
    end
    timing.filtering = toc(start);
    save(fil_match_f_name, 'sel_model_i', 'sel_corr', 'sel_adj_mat');
else
    load(fil_match_f_name);
    if interactive; fprintf('filtered matches loaded\n'); end
end

% Estimate pose.
query_poses = query_frames(1:2,:);
start = tic;
[transforms, rec_indexes] = estimate_multi_pose(query_poses, points, sel_model_i, ...
    sel_corr, sel_adj_mat, models, obj_names, query_im_name, options, interactive);
timing.ransac = toc(start);

timing.total = timing.matching + timing.filtering + timing.ransac;

% Create results.
count = length(rec_indexes);
results.objcount = count;
results.objnames = cell(count, 1);
results.transforms = cell(count, 1);
obj_names = obj_names(rec_indexes);
for i = 1 : count
    results.objnames{i} = obj_names{i};
    results.transforms{i} = transforms{i};
end
