clearvars;

matches_f_name = 'data/matches_anchiceratops_dense.mat';
matches = load(matches_f_name);
matches3d = matches.matches3d;
matches2d = matches.matches2d;

while iscell(matches3d{1})
    matches3d = [matches3d{1}{1}; [{matches3d{1}{2}}; matches3d(2:length(matches3d))]];
end

save(matches_f_name, 'matches2d', 'matches3d');
