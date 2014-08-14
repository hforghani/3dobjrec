function [sol, error] = pnp_grad_descent(corr, q_frames, points, model)

max_pnp_error = 3;
stop_cri = 0.01;
max_iter = 50;

poses = model.get_poses();
matched_poses = poses(:, points(2,:));
ccount = size(corr,2);
K = model.calibration.get_calib_matrix();

% Initialize.
sol = ones(ccount,1);
[~, ~, error] = solve_pnp(sol, corr, matched_poses, q_frames, K);
pre_error = Inf;

% Run gradient descent.
i = 0;
while i < max_iter && abs(error - pre_error) > stop_cri
    toggle_errors = zeros(ccount, 1);
    
    for j = 1 : ccount
        if sum(sol) == 3 && sol(j) == 1
            toggle_errors(j) = Inf;
            continue;
        end
        
        new_sol = sol;
        new_sol(j) = 1 - new_sol(j); % Toggle j'th element.
        [~, ~, toggle_errors(j)] = solve_pnp(new_sol, corr, matched_poses, q_frames, K);
    end
    
    [cur_error, min_i] = min(toggle_errors);    
    
    pre_error = error;
%     if cur_error < error || (sol(min_i) == 0 && cur_error < max_pnp_error)
    if cur_error < error
        error = cur_error;
        sol(min_i) = 1 - sol(min_i); % Toggle min_i'th element.
    end
    
    i = i + 1;
end


end


function [R, T, error] = solve_pnp(sol, corr, matched_poses, q_frames, K)
    indexes3d = corr(2, logical(sol));
    indexes2d = corr(1, logical(sol));
    poses3d = matched_poses(:, indexes3d);
    poses2d = q_frames(1:2, indexes2d);
    x3d_h = [poses3d; ones(1, sum(sol))];
    x2d_h = [poses2d; ones(1, sum(sol))];

    [R, T, ~, ~, ~] = efficient_pnp_gauss(x3d_h', x2d_h', K);
    error = reprojection_error_usingRT(poses3d', poses2d', R, T, K);
end
