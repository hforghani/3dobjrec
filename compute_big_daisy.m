function compute_big_daisy(im)
    [x,y] = size(im);
    patch_size = 100;
    for i = 1:patch_size:x
        end_i = min(i + patch_size, x);
        for j = 1:patch_size:y
            end_j = min(j + patch_size, y);
            
        end
    end
end