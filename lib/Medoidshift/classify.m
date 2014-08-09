function [ar_mode] = classify2(I)
% Tree Traversal

ar_path = zeros(size(I));
ar_mode = zeros(size(I));

%for each point
for i=1:size(I,2)   
    [ar_mode(i),ar_path] = findMode(I(i),I,ar_path);
    ar_path(i) = 1;
end

% Recursion
function [mode, ar_path] = findMode(curr,I,ar_path)

if(curr == I(curr))
    mode = curr;
else
    [mode, ar_path] = findMode(I(curr),I,ar_path);
end
ar_path(curr) = 1;