function test_ransac()
    x = [1 2 3 4;
         3 4 45 5];
    disp(fit_line(x(:,1:2)));
    [M, inliers] = ransac(x, @fit_line, @dist_to_line, @degenfn, 2, 0.1)
    
    b = M(1);
    c = M(2);
    x1 = min(x(1,:));
    x2 = max(x(1,:));
    y1 = - x1/b + c/b;
    y2 = - x2/b + c/b;
    
    scatter(x(1,:), x(2,:));
    hold on;
    plot([x1 x2], [y1 y2]);
end

function line = fit_line(x)
    x1 = x(1,1);
    y1 = x(2,1);
    x2 = x(1,2);
    y2 = x(2,2);
    m = (y2-y1) / (x2-x1);
    b = y1 - m * x1;
    line = [-1/m,  b/m];
end

function [inliers, M] = dist_to_line(M, x, t)
    if ~iscell(M)
        M = {M};
    end
    max_inliers = -1;
    for i = 1:length(M)
        model = M{i};
        b = model(1);
        c = model(2);
        dist = abs(x(1,:) + b*x(2,:) + c*ones(1,size(x,2))) / (1+b^2)^0.5;
        cur_inliers = find(dist < t);
        if length(cur_inliers) > max_inliers
            max_inliers = length(cur_inliers);
            inliers = cur_inliers;
            best_model = model;
        end
    end
    M = best_model;
end

function r = degenfn(x)
    r = 0;
end
