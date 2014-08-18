function cons = cons_tri_angle(model_corr, model_points, q_frames, model)

start = tic;

ccount = size(model_corr, 2);
pcount = size(model_points, 2);
poses = model.get_poses();
matched_poses = poses(:, model_points(2,:));

covis = cons_covis3d(model_points, model.points, model_corr, true(ccount));

cons = zeros(ccount, ccount, ccount);
sigma = 0.2;
max_dist = 0.1;

if isempty(covis)
    return;
end

for x = 1 : ccount-2
    for y = x+1 : ccount-1
        for z = y+1 : ccount
            
            corr = model_corr(:, [x y z]);
            p_indexes = corr(2,:);
            
            if covis(p_indexes(1), p_indexes(2)) && covis(p_indexes(2), p_indexes(3)) && covis(p_indexes(1), p_indexes(3)) ...
                    && length(unique(p_indexes)) == 3 && length(unique(corr(1,:))) == 3
                
                poses3d = matched_poses(:, p_indexes);
                poses2d = q_frames(1:2, corr(1,:));

                theta3d = middle_angle(poses3d);
                theta2d = middle_angle(poses2d);
        %         ratio = theta2d / theta3d;
                dist = theta2d - theta3d;

                if abs(dist) < max_dist
                    cons(x,y,z) = exp(-.5 * (dist/sigma) .^ 2);
                end
            end
        end
    end
end

permu = perms([1 2 3]);
for i = 2 : length(permu)
    cons = max(cons, permute(cons, permu(i,:)));
end

fprintf('cons_tri_angle : %f\n', toc(start));

end


function angle = middle_angle(poses)
    a = poses(:,2) - poses(:,1);
    b = poses(:,3) - poses(:,1);
    angle = acos(dot(a,b) / (norm(a)*norm(b)));
end
