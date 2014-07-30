function [sol, score] = grad_ascent_gm(M, sol0, stop_cri, max_iter, interactive)

if nargin < 5; interactive = false; end
if nargin < 4; max_iter = 50; end
if nargin < 3; stop_cri = 0.01; end

score = sol0' * M * sol0;
if sol0 ~= 0
    score = score / (norm(sol0) ^ 2);
end
sol = sol0;
pre_score = 0;

if interactive; fprintf('\ngradient ascent scores: %f', score); end

i = 0;

while abs(score - pre_score) > stop_cri && i < max_iter
    delta = 2 * sum(M,2) .* sol - diag(M);
    
    [~, max_i] = max(delta(sol == 0));
    nnz_i = find(~sol);
    max_i = nnz_i(max_i);
    
    [~, min_i] = min(delta(sol == 1));
    z_i = find(sol);
    min_i = z_i(min_i);
    
    sol_max = sol;
    sol_min = sol;
    sol_max(max_i) = 1;
    sol_min(min_i) = 0;
    
    max_score = sol_max' * M * sol_max;
    if sol_max ~= 0
        max_score = max_score / (norm(sol_max) ^ 2);
    end
    min_score = sol_min' * M * sol_min;
    if sol_min ~= 0
        min_score = min_score / (norm(sol_min) ^ 2);
    end
    pre_score = score;
    
    if max_score > min_score && max_score > score
        score = max_score;
        sol = sol_max;
        if interactive; fprintf(' -> %f', score); end
    elseif min_score > max_score && min_score > score
        score = min_score;
        sol = sol_min;
        if interactive; fprintf(' -> %f', score); end
    end
    
    i = i + 1;
end

if interactive; fprintf('\n'); end

end
