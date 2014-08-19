function [sol, score] = grad_ascent_gm_tri(M, sol0, varargin)
% graph matching by the gradient ascent method with affinity matrix of size
% C*C*C (triple consistency)

% start = tic;

interactive = false;
max_iter = 50;
stop_cri = 0.1;
guide_graph = [];

i = 1;
while i <= length(varargin)
    if strcmp(varargin{i}, 'StopCriteria')
        stop_cri = varargin{i+1};
    elseif strcmp(varargin{i}, 'MaxIteration')
        max_iter = varargin{i+1};
    elseif strcmp(varargin{i}, 'Interactive')
        interactive = varargin{i+1};
    elseif strcmp(varargin{i}, 'GuideGraph')
        guide_graph = varargin{i+1};
    end
    i = i + 2;
end

score = graph_match_score(sol0, M);
sol = sol0;
pre_score = 0;

if interactive; fprintf('\ngradient ascent scores: %f', score); end

i = 0;

while abs(score - pre_score) > stop_cri && i < max_iter
    if ~isempty(guide_graph)
        next_vertices = false(size(sol));
        for j = find(sol)'
            next_vertices = next_vertices | guide_graph(:,j);
        end
        next_vertices = next_vertices & (sol == 0);
    else
        next_vertices = sol == 0;
    end
    
    delta = zeros(size(sol));
    for j = (next_vertices | sol ~= 0)'
        delta(j) = 3 * sol' * M(:,:,j) * sol - 3 * sol' * M(:,j,j) + M(j,j,j);
    end
    
    [~, max_i] = max(delta(next_vertices));
    nnz_i = find(next_vertices);
    max_i = nnz_i(max_i);
    
    [~, min_i] = min(delta(sol == 1));
    z_i = find(sol);
    min_i = z_i(min_i);
    
    sol_max = sol;
    sol_min = sol;
    sol_max(max_i) = 1;
    sol_min(min_i) = 0;
    
    max_score = graph_match_score(sol_max, M);
    min_score = graph_match_score(sol_min, M);
    
    pre_score = score;
    
    if min_score >= max_score && min_score > score
        score = min_score;
        sol = sol_min;
        if interactive; fprintf(' -> %f', score); end
    elseif max_score >= min_score && max_score > score
        score = max_score;
        sol = sol_max;
        if interactive; fprintf(' -> %f', score); end
    end
    
    i = i + 1;
end

if interactive; fprintf('\n'); end

% fprintf('grad_ascent_gm_tri : %f\n', toc(start));

end
