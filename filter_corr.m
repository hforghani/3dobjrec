function indexes = filter_corr(matches2d, matches3d)

kdtree = vl_kdtreebuild(double(matches2d));
point_count = size(matches2d, 2);
indexes = [];
for i = 1:point_count;
    point = matches2d(:,i);
    [index, distance] = vl_kdtreequery(kdtree, double(matches2d), point);
    if distance < 30
        indexes = [indexes, i];
    end
end

end