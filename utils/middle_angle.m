function angle = middle_angle(poses)
    a = poses(:,2) - poses(:,1);
    b = poses(:,3) - poses(:,1);
    angle = acos(dot(a,b) / (norm(a)*norm(b)));
end
