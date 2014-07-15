function match_and_estimate(case_name, query_im_name, models, load_match, load_fil_match, param, value)

% Check parameter arguments.
if ~exist('load_match', 'var')
    load_match = false;
end
if ~exist('load_fil_match', 'var')
    load_fil_match = false;
end
alg = 'filter';
if exist('param', 'var') && strcmp(param, 'Algorithm')
    if strcmp(value, 'filter') || strcmp(value, 'graphmatch')
        alg = value;
    else
        error('%s is not a valid algorithm', value);
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
    switch alg
        case 'filter'
            [sel_model_i, sel_corr, sel_adj_mat] = ...
                filter_corr(query_frames, points, correspondences, corr_dist, models, desc_model.obj_names, query_im_name);
            save(fil_match_f_name, 'sel_model_i', 'sel_corr', 'sel_adj_mat');
        case 'graphmatch'
            [sel_model_i, sel_corr, sel_adj_mat] = ...
                match_corr_graph(query_frames, points, correspondences, corr_dist, models, desc_model.obj_names, query_im_name);
            save([fil_match_f_name '_gr'], 'sel_model_i', 'sel_corr', 'sel_adj_mat');
    end
    toc;
else
    switch alg
        case 'filter'
            load(fil_match_f_name);
        case 'graphmatch'
            load([fil_match_f_name '_gr']);
    end    
    fprintf('filtered matches loaded\n');
end

% Estimate pose.
tic;
query_poses = query_frames(1:2,:);
mode = 'regular';
switch alg
    case 'filter'
        mode = 'graph';
    case 'graphmatch'
        mode = 'regular';
end    
[transforms, rec_indexes] = estimate_multi_pose(query_poses, points, sel_model_i, sel_corr, sel_adj_mat, models, desc_model.obj_names, query_im_name, 'SamplingMode', mode);
toc;

% Save results as ply and txt.
fprintf('saving results ... ');
if strcmp(alg, 'graphmatch')
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
