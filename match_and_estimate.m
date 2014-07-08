function match_and_estimate(case_name, query_im_name, models, load_match, load_fil_match)

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
if ~exist('load_match', 'var')
    load_match = false;
end
if ~exist('load_fil_match', 'var')
    load_fil_match = false;
end

% Match 2d to 3d
tic;
if ~load_match
    image = imread(query_im_name);
    [query_frames, correspondences, points, corr_dist] = match_2d_to_3d(image, desc_model);
    save(matches_f_name, 'query_frames', 'points', 'correspondences', 'corr_dist');
else
    load(matches_f_name);
    fprintf('matches loaded\n');
end
toc;

% Filter correspondences.
fprintf('filtering correspondences ...\n');
tic;
if ~load_fil_match
    [sel_model_i, sel_corr, sel_adj_mat] = ...
        filter_corr(query_frames, points, correspondences, corr_dist, models, desc_model.obj_names, query_im_name);
    % [sel_model_i, sel_corr, sel_adj_mat] = ...
    %     match_corr_graph(query_frames, points, correspondences, corr_dist, models, desc_model.obj_names, query_im_name);
    save(fil_match_f_name, 'sel_model_i', 'sel_corr', 'sel_adj_mat');
else
    load(fil_match_f_name);
    fprintf('filtered matches loaded\n');
end
toc;

% Estimate pose.
tic;
query_poses = query_frames(1:2,:);
[transforms, rec_indexes] = estimate_multi_pose(query_poses, points, sel_model_i, sel_corr, sel_adj_mat, models, desc_model.obj_names, query_im_name);
toc;

% Save results as ply and txt.
fprintf('saving results ... ');
create_ply(transforms, rec_indexes, desc_model.obj_names, ply_fname);
fid = fopen(res_fname, 'w');
fprintf(fid, 'recognized objects:\n');
fprintf(fid, '%d\n', length(rec_indexes));
for i = 1:length(rec_indexes)
    fprintf(fid, '%s\n', desc_model.obj_names{rec_indexes(i)});
end
fclose(fid);
fprintf('done\n');
