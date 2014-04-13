function descriptors = devide_and_compute_daisy(im, points)
    [h, w] = size(im);
    patch_size = 300;
    offset = 10;
    
%     show_points(im, points, patch_size)

    descriptors = zeros(200, size(points,2));
    for i1 = 1 : patch_size : w
        display_i1 = max(i1-offset, 1);
        i2 = min(i1 + patch_size, w);
        display_i2 = min(i2 + offset, w);
        for j1 = 1 : patch_size : h
            display_j1 = max(j1-offset, 1);
            j2 = min(j1 + patch_size, h);
            display_j2 = min(j2 + offset, h);
            patch = im(display_j1:display_j2, display_i1:display_i2);
            is_in_patch = points(1,:) >= i1 & points(1,:) <= i2 ...
                        & points(2,:) >= j1 & points(2,:) <= j2;
            points_in_patch = points(:, is_in_patch);
            if isempty(points_in_patch)
                continue;
            end
            dzy = compute_daisy(patch);
            desc_in_patch = zeros(200, size(points_in_patch, 2));
            for k = 1:size(points_in_patch, 2)
%                 scatter(points_in_patch(1,k), points_in_patch(2,k), 'y');
                x_in_patch = round(points_in_patch(1,k) - display_i1 + 1);
                y_in_patch = round(points_in_patch(2,k) - display_j1 + 1);
                desc = display_descriptor(dzy, y_in_patch, x_in_patch);
                desc_in_patch(:, k) = reshape(desc, 200, 1);
%                 scatter(points_in_patch(1,k), points_in_patch(2,k), 'g');
            end
            descriptors(:, is_in_patch) = desc_in_patch;
        end
    end
end

function show_points(im, points, patch_size)
    [h, w] = size(im);
    imshow(im, [0 255]);
    hold on;
    scatter(points(1,:), points(2,:), 'r');
    for i = 1 : patch_size : w
        plot([i, i], [1, h]);
    end
    for j = 1 : patch_size : h
        plot([1, w], [j, j]);
    end
end