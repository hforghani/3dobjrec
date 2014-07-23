function match_and_estimate(case_name, query_im_name, models, varargin)

load_match = false;
load_fil_match = false;
method = 'gm';
interactive = false;

% Check parameter arguments.
if nargin > 3
    i = 1;
    while i <= length(varargin)
        if strcmp(varargin{i}, 'LoadMatches')
            load_match = varargin{i+1};
        elseif strcmp(varargin{i}, 'LoadFiltered')
            load_fil_match = varargin{i+1};
        elseif strcmp(varargin{i}, 'Method')
            method = varargin{i+1};
            if ~strcmp(method, 'filter') && ~strcmp(method, 'gm')
                error('%s is not a valid method', method);
            end
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
fil_match_f_name = ['data/matches/' case_name '_' exact_name '_fil'];
desc_model_f_name = ['data/model_desc/' case_name];
desc_model = load(desc_model_f_name);
ply_fname = ['result/res_' exact_name '.ply'];
res_fname = ['result/res_' exact_name '.txt'];

% Match 2d to 3d
if ~load_match
    image = imread(query_im_name);
    tic;
    [query_frames, correspondences, points, corr_dist] = match_2d_to_3d(image, desc_model, models);
    toc;
    save(matches_f_name, 'query_frames', 'points', 'correspondences', 'corr_dist');
else
    load(matches_f_name);
    fprintf('matches loaded\n');
end

% Filter correspondences.
if ~load_fil_match
    fprintf('filtering correspondences ...\n');
    tic;
    switch method
        case 'filter'
            [sel_model_i, sel_corr, sel_adj_mat] = ...
                filter_corr(query_frames, points, correspondences, models, desc_model.obj_names, query_im_name, interactive);
            save(fil_match_f_name, 'sel_model_i', 'sel_corr', 'sel_adj_mat');
        case 'gm'
            [sel_model_i, sel_corr, sel_adj_mat] = ...
                match_corr_graph(query_frames, points, correspondences, corr_dist, models, desc_model.obj_names, query_im_name, interactive);
            save([fil_match_f_name '_gr'], 'sel_model_i', 'sel_corr', 'sel_adj_mat');
    end
    toc;
else
    switch method
        case 'filter'
            load(fil_match_f_name);
        case 'gm'
            load([fil_match_f_name '_gr']);
    end    
    fprintf('filtered matches loaded\n');
end

% Estimate pose.
tic;
query_poses = query_frames(1:2,:);
mode = 'regular';
switch method
    case 'filter'
        mode = 'graph';
    case 'gm'
        mode = 'graph';
end    
[transforms, rec_indexes] = estimate_multi_pose(query_poses, points, sel_model_i, sel_corr, sel_adj_mat, models, desc_model.obj_names, query_im_name, 'SamplingMode', mode);
toc;

% Save results as ply and txt.
fprintf('saving results ... ');
if strcmp(method, 'gm')
    ply_fname = [ply_fname(1:end-4) '_gr.ply'];
    res_fname = [res_fname(1:end-4) '_gr.txt'];
end
create_ply(transforms, rec_indexes, desc_model.obj_names, ply_fname);
fid = fopen(res_fname, 'w');
fprintf(fid, 'recognized objects:\n');
fprintf(fid, '%d\n', length(rec_indexes));
for i = 1:length(rec_indexes)
    fprintf(fid, '%s\n', desc_model.obj_names{rec_indexes(i)});
end
fclose(fid);
fprintf('done\n');
