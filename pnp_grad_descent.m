function [sol, error] = pnp_grad_descent(corr, q_frames, points, model)

sample_count = 100;
max_pnp_error = 3;

poses = model.get_poses();
matched_poses = poses(:, points(2,:));

ccount = size(corr,2);
combs = nchoosek(1:ccount, 3);

sample_indexes = randi(size(combs,1), sample_count, 1);
rot_arr = zeros(9, sample_count);
trans_arr = zeros(3, sample_count);
errors = zeros(1, sample_count);

K = model.calibration.get_calib_matrix();

% Randomly sample 3 matches and compute P3P.
for i = 1 : sample_count
    sol_indexes = combs(sample_indexes(i), :);
    indexes2d = corr(1, sol_indexes);
    indexes3d = corr(2, sol_indexes);
    poses3d = matched_poses(:, indexes3d);
    poses2d = q_frames(1:2, indexes2d);
    x3d_h = [poses3d; ones(1,3)];
    x2d_h = [poses2d; ones(1,3)];
    
    try
        [R, T, ~, ~, ~] = efficient_pnp_gauss(x3d_h', x2d_h', K);
        errors(i) = reprojection_error_usingRT(poses3d', poses2d', R, T, K);
    catch
        errors(i) = Inf;
    end
    
    rot_arr(:,i) = reshape(R, 9, 1);
    trans_arr(:,i) = T;
    
end

% Validate samples.
valid_samples = errors < max_pnp_error;
if ~any(valid_samples); sol = zeros(ccount,1); error = 0; return; end

sample_indexes = sample_indexes(valid_samples);
rot_arr = rot_arr(:, valid_samples);
trans_arr = trans_arr(:, valid_samples);
errors = errors(valid_samples);

% mode seeking on R,T pairs.
transforms = [rot_arr; trans_arr];
D = dist(transforms) .^2 ; % Compute Distance Matrix
sigma = max(max(D)) / 4;
[mode_arr, iter] = medoidshift(D, sigma);

[Y, eigvals] = cmdscale(sqrt(D));
if size(Y,2) >= 2 && any(any(Y ~= 0))
% plot(Y(:,1),Y(:,2),'.');'
try
    visualizeClustering(mode_arr, Y(:,1:2)'); % Visualize Result
catch e
    0;
end
end

% Find main cluster, initial solution and its error.
main_mode = mode(mode_arr);
sol_indexes = combs(sample_indexes(main_mode), :);
sol = zeros(ccount,1);
sol(sol_indexes) = 1;
error = errors(main_mode);
cur_error = error;
pre_error = Inf;

% Run gradient descent.

stop_cri = 0.01;
max_iter = 50;
i = 0;

while i < max_iter && cur_error < max_pnp_error && abs(error - pre_error) > stop_cri
    toggle_errors = zeros(ccount, 1);
    
    for j = 1 : ccount
%         if sum(sol) == 3 && sol(j) == 1
        if sol(j) == 1
            toggle_errors(j) = Inf;
            continue;
        end
        
        new_sol = sol;
        new_sol(j) = 1 - new_sol(j); % Toggle j'th element.
        
        indexes2d = corr(2, logical(new_sol));
        indexes3d = corr(1, logical(new_sol));
        poses3d = matched_poses(:, indexes2d);
        poses2d = q_frames(1:2, indexes3d);
        x3d_h = [poses3d; ones(1, sum(new_sol))];
        x2d_h = [poses2d; ones(1, sum(new_sol))];
        
        [R, T, ~, ~, ~] = efficient_pnp_gauss(x3d_h', x2d_h', K);
        toggle_errors(j) = reprojection_error_usingRT(poses3d', poses2d', R, T, K);
    end
    
    [cur_error, min_i] = min(toggle_errors);    
    
%     if cur_error < error || (sol(min_i) == 0 && cur_error < max_pnp_error)
    if cur_error < max_pnp_error
        pre_error = error;
        error = cur_error;
        sol(min_i) = 1 - sol(min_i); % Toggle min_i'th element.
    end
    
    i = i + 1;
end


end
