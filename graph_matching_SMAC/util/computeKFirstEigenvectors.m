function [X,lambda,timing,D] = computeKFirstEigenvectors(W,nbEigenvectors,isncut,D);
%{
%TODO:revert to eig when needed
% Timothee Cour, 21-Apr-2008 17:31:23
% This software is made publicly for research use only.
% It may be modified and redistributed under the terms of the GNU General Public License.


computes first k (normlalized-cuts) eigenvectors of W
input:
W: nxn affinity matrix
nbEigenvectors: # eigenvectors requested (k)
isncut: 0 for eigenvectors, 1 for normlalized-cuts eigenvectors
D: optional parameter, can be set to diagonal of degree matrix of W; it
is computed when not specified
X: nxk eigenvectors
lambda: kx1 eigenvalues
timing: timing information
typical calling sequence:
[X,lambda] = computeKFirstEigenvectors(W,nbEigenvectors,1);
%}

if nargin < 3
    isncut = 1;
end

n = size(W,1);

[options,nbEigenvectors] = getDefaultOptionsEigs(n,nbEigenvectors);

if isncut
    if nargin>=4
        D=D(:);
        Dinvsqrt = 1./sqrt(D+eps);
        W=normalizeW_D(W,Dinvsqrt);
    else
        [W,Dinvsqrt,D]=normalizeW_D(W,[],0);
    end
end

if issparse(W) && mex_istril(W)    
%     [result,timing] = eigs_optimized(@mex_w_times_x_symmetric_tril,[],nbEigenvectors,options,tril(W));
    [result,timing] = eigs_optimized(@mex_w_times_x_symmetric_tril,[],nbEigenvectors,options,W);
else
    [result,timing] = eigs_optimized(W,[],nbEigenvectors,options);
end
X = result.X;
if isncut
    X = spdiag(Dinvsqrt) * X;
end

lambda = result.lambda;
mex_normalizeColumns(X);



