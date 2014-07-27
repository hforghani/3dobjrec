function res = has_intersect( arr1, arr2 )

s1 = sort(arr1);
s2 = sort(arr2);
i1 = 1;
i2 = 1;

res = false;

while i1 <= length(arr1) && i2 <= length(arr2)
    if s1(i1) < s2(i2)
        i1 = i1 + 1;
    elseif s1(i1) > s2(i2)
        i2 = i2 + 1;
    else
        res = true;
        break;
    end
end

end
