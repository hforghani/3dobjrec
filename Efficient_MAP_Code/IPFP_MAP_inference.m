

%% author: Marius Leordeanu
% last updated: June 20, 2011

% for questions contact the author at: leordeanu@gmail.com


%% please cite the following paper:
%  
% An Integer Projected Fixed Point Method for Graph Matching and MAP
% Inference, NIPS 2009
% by Marius Leordeanu ,  Martial Hebert ,  Rahul Sukthankar 

% Utility:

% used for Maximum A Posteriori (MAP) labeling (discrete inference) problems

% it tries to maximize the labeling score x'Mx + Dx, 
% where x obeys discrete many-to-one labeling constraints 
% such that x(i) = 1 if node (or site) nodes(i) is labeled with labels(i)
% and 0 otherwise (another version of this algorithm for QAP problems with
% 1-to-1 constraints is also avaliable)


% Input: 
%       sol0: initial solution
%       M:    matrix with pairwise potentials
%       D:    vector with unary potentials
%       labels, nodes: vectors of same size as D, indexing the candidate
%       labels; pairs of type site -> possible label are contained in (nodes(i),
%       labels(i))



function [sol, score] = IPFP_MAP_inference(M, D, sol0, labels, nodes)

tic;

n = length(labels);

nSteps = 0;

nLabels = max(labels);
nNodes = max(nodes);

nNodes = max(nodes);

sol = sol0;

for j = 1:nNodes
    
    f{j} = find(nodes == j);
    sol(f{j}) = sol(f{j})/sum(sol(f{j})+0.000001); 

end

new_sol = sol0;

best_sol = sol0;

best_score = 0; 

old_sol = new_sol;

while 1
       
   %oldScore = new_sol'*M*old_sol;
     
   nSteps =  nSteps + 1; 
    
   %disp(nSteps)
   
   old_sol = new_sol;
      
   new_sol = zeros(n,1);

   xx =  2*M*old_sol + D;

   for j = 1:nNodes
       
    [el_max, ind_max] = max(xx(f{j})); 
    
    x2(f{j}) = 0;
    x2(f{j}(ind_max)) = 1;

   end
 
   x2 = x2(:);
  
   v = x2 - old_sol;
   
   k = v'*M*v;
     
   if k >= 0
   
       new_sol = x2;
        
   else
 
       c = 2*old_sol'*M*v+D'*v;
       
       t = min([1, -c/(2*k)]);
       
       if t < 0.0001
           t = 0;
       end
       
       new_sol = old_sol + t*v;
            
   end
   
%    if x2'*M*x2 + D'*x2 > best_score
%        
%         best_score = x2'*M*x2+D'*x2;
%         
%         best_sol = x2;
%       
%    end
      
   if norm(new_sol - old_sol) == 0
       break;
   end
    
end

nSteps

sol = new_sol;

score = sol'*M*sol + D'*sol;

time = toc;

disp('time for IPFP MAP');

time

return