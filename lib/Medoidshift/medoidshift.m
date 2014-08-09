function [ar_mode2, iter] = medoidshift(D,sigma)
% [ar_mode2, iter] = medoidshift(D,sigma)
% D         Distance Matrix
% sigma     Bandwidth parameter
% ar_mode2  Pointer array to modes
% iter      Number of iterations   

sw = 1;
modes = 1:length(D);
ar_mode = modes;
ar_mode2 = modes;

v = NaN;
w = ones(1,length(D));
iter = 0;

while(sw)
    modes_old = sort(modes);
    ar_mode_old = ar_mode2;

    r = sigma;
    [ar_mode] = medoidshiftIterative(D,v,sigma); % ar_mode pointer to the mode in D
    [modes,I,J] = unique(ar_mode);

    % Create a new reduced distance matrix of modes
    D = D(modes,modes);

    % Convert ar_mode to original datapoint labels
    ar_mode = modes_old(ar_mode);
    modes = ar_mode(I);

    for i = 1:length(modes_old)
        ind = find(modes_old(i)==ar_mode2);
        ar_mode2(ind) = ar_mode(i);
    end

    % Create Weight Matrix
    w_new = [];
    for i = 1:length(modes),
        w_new(i) = sum(w(find(modes(i)==ar_mode)));
    end

    w = w_new;
    v = diag(w);

    if(prod(double(ar_mode2 == ar_mode_old)))
        break;
    end

    iter = iter + 1;
end