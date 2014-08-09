function [ar_mode,I,S,D,W] = medoidshiftIterative(D,lambda,sigma)
% [ar_mode,I,S,D,W] = medoidshift_iterative(D,lambda,sigma)
% D:      Distance Matrix
% sigma:  Bandwidth parameter
% lambda: Votes for a point
% if v is an identity matrix replace with NaN

W = exp(-0.5*D/sigma);

if(~isnan(lambda))
    S = D*lambda*W;
else
    S = D*W;
end

[y,I] = min(S,[],1);
ar_mode = classify(I);
