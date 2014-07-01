function gplot3(A, xyz)
    % GPLOT3(A, xyz) is nearly the same as GPLOT(A, xy) except
    % that the xyz variable requires a third dimension.
    % This function takes an adjacency matrix and visualizes it
    % in 3D.
    [d e] = size(A);
    if d ~= e
        error('A matrix must be square.');
    end

    [points f] = size(xyz);
    if f ~= 3
        error('xyz matrix must be of width 3');
    end

    if points ~= d
        error('Width of A must equal height of xyz.');
    end

    xp = [];
    xq = [];
    yp = [];
    yq = [];
    zp = [];
    zq = [];

    for i = 1:(d-1)
        for j = i:d
            if A(i,j) ~= 0
                xp = [xp xyz(i, 1)];
                xq = [xq xyz(j, 1)];
                yp = [yp xyz(i, 2)];
                yq = [yq xyz(j, 2)];
                zp = [zp xyz(i, 3)];
                zq = [zq xyz(j, 3)];
            end
        end
    end
    line([xp; xq], [yp; yq], [zp; zq]);
end