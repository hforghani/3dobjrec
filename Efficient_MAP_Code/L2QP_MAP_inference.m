
%% author: Marius Leordeanu
% last updated: June 20, 2011

% for questions contact the author at: leordeanu@gmail.com


%% Please cite the paper describing the algorithm:

%  Marius Leordeanu and Martial Hebert,
%  Efficient MAP approximation for dense energy functions,
%  International Conference on Machine Learning, May, 2006. 


% Utility:

% used for Maximum A Posteriori (MAP) labeling (discrete inference) problems

% it tries to maximize the labeling score x'Mx + Dx, 
% where x obeys discrete many-to-one labeling constraints 
% such that x(i) = 1 if node (or site) nodes(i) is labeled with labels(i)
% and 0 otherwise (another version of this algorithm for QAP problems with
% 1-to-1 constraints is also avaliable)


% Input: 

%       M:    matrix with pairwise potentials
%       D:    vector with unary potentials
%       labels, nodes: vectors of same size as D, indexing the candidate
%       labels; pairs of type site -> possible label are contained in (nodes(i),
%       labels(i))
%       iterEigen: nr of iterations of the initial stage (approx 30) 
%       iterClimb: nr of iterations of the final stage   (approx 200)

function [sol, score, V] = L2QP_MAP_inference(M, D, labels, nodes, iterEigen, iterClimb)

tic;

% FAST_OPTION = 0; %set this to 1 for parallel updates (no theoretical guarantees)

n = size(M,1);

v = ones(n,1);

nNodes = max(nodes);

for j = 1:nNodes
    
    f{j} = find(nodes == j);
    
end

%% Stage 1: obtain the starting point using the normalized power/eigen method
%           this finds the global maximum to the relaxed problem

for i = 1:iterEigen
   
   v = (M*v);
      
  for j = 1:nNodes
    
    v(f{j}) = v(f{j})/(norm(v(f{j})+ 0.000001)); 
     
  end
  
end

V = v;

%now start from v, project in on the simplex, and keep climbing using a similar iterative method
%project v on the simplex

for j = 1:nNodes
    
    v(f{j}) = v(f{j})/sum(v(f{j})+0.000001); 
     
end

%% Stage 2: climb until convergence 

score1 = v'*M*v;

step = 1/iterClimb;
beta = [1:-step:0.03];

iterClimb = length(beta);

beta = 1./beta;

for i = 1:iterClimb

%     if FAST_OPTION == 1
%         
%         v = v.*((M*v + 0.5*D).^beta(i));
%         
%     end
  
  for j = 1:nNodes

%     if FAST_OPTION == 0


      v(f{j}) = v(f{j}).*((2*M(f{j},:)*v + D(f{j})).^beta(i));
         
%     end
         
        
      v(f{j}) = v(f{j})/sum(v(f{j})+0.000001); 
     
  end
  

  
end

%keyboard;



%------------------------------------

sol = zeros(n,1);

for j = 1:nNodes
    
    [m, ind] = max(v(f{j}));
      
    ind = f{j}(ind);
    
    sol(ind) = 1;
       
end

score = sol'*M*sol + D'*sol;

disp('time for L2QP MAP');

toc;

return