function new_pointer_array = reindex_arr(ref_array, pointer_array)
% Some components of pointer_array are equal to the value of one component 
% of ref_array. Suppose the values of ref_array has been changed to 1, 2, ..., n. 
% Change the values of pointer_array in such a way that will be equal to
% the same component of new ref_array.
    new_pointer_array = zeros(size(pointer_array));
    for i = 1:length(ref_array)
        new_pointer_array(pointer_array == ref_array(i)) = i;
    end
end
