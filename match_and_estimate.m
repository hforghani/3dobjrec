function [results, timing] = match_and_estimate(case_name, query_im_name, models, varargin)

load_match = false;
load_fil_match = false;
method = 'gm';
interactive = 0;

estimation_mode = 'guidedRansac'; % choices: guidedRansac, ransac, noSample
min_inl_ratio = 0;
min_inl_count = 12;

% Check parameter arguments.
if nargin > 3
    i = 1;
    while i <= length(varargin)
        if strcmp(varargin{i}, 'LoadMatches')
            load_match = varargin{i+1};
        elseif strcmp(varargin{i}, 'LoadFiltered')
            load_fil_match = varargin{i+1};
        elseif strcmp(varargin{i}, 'Local')
            local_method = varargin{i+1};
        elseif strcmp(varargin{i}, 'Global')
            global_method = varargin{i+1};
        elseif strcmp(varargin{i}, 'Interactive')
            interactive = varargin{i+1};
        end
        i = i + 2;
    end
end


% Initialize.
parts = textscan(query_im_name, '%s', 'delimiter', '/');
parts = textscan(parts{1}{end}, '%s', 'delimiter', '.');
exact_name = parts{1}{1};
matches_f_name = ['data/matches/' case_name '_' exact_name];
fil_match_f_name = ['data/matches/' case_name '_' exact_name '_' local_method '_' global_method];
desc_model_f_name = ['data/model_desc/' case_name];
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
    if strcmp(local_method, 'hao') && strcmp(global_method, 'hao')
        [sel_model_i, sel_corr, sel_adj_mat] = ...
            filter_corr(query_frames, points, correspondences, models, obj_names, ...
            query_im_name, interactive);
    else
        [sel_model_i, sel_corr, sel_adj_mat] = ...
            graph_match_corr(query_frames, points, correspondences, corr_dist, ...
            models, obj_names, query_im_name, 'Interactive', interactive, ...
            'Local', local_method, 'Global', global_method);
    end
    timing.filtering = toc(start);
    save(fil_match_f_name, 'sel_model_i', 'sel_corr', 'sel_adj_mat');
else
    switch method
        case 'filter'
            load(fil_match_f_name);
        case 'gm'
            load([fil_match_f_name '_gm']);
    end    
    if interactive; fprintf('filtered matches loaded\n'); end
end

% Estimate pose.
query_poses = query_frames(1:2,:);
start = tic;
[transforms, rec_indexes] = estimate_multi_pose(query_poses, points, sel_model_i, ...
    sel_corr, sel_adj_mat, models, obj_names, query_im_name, ...
    'SamplingMode', estimation_mode, 'MinInlierRatio', min_inl_ratio, 'MinInlierCount', ...
    min_inl_count, 'Interactive', interactive);
timing.ransac = toc(start);

timing.total = timing.matching + timing.filtering + timing.ransac;

% Create results.
count = length(rec_indexes);
results = cell(count, 1);
obj_names = obj_names(rec_indexes);
for i = 1 : count
    results{i} = struct('obj_index', rec_indexes(i), 'obj_name', obj_names{i}, ...
        'transform', transforms{i});
end
