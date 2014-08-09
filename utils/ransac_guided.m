% RANSAC - Robustly fits a model to data with the RANSAC algorithm
%
% Usage:
%
% [M, inliers] = ransac_graph_samp(x, adj_mat, fittingfn, distfn, degenfn ,s, t, feedback, ...
%                       maxDataTrials, maxTrials)
%
% Arguments:
%     x         - Data sets to which we are seeking to fit a model M
%                 It is assumed that x is of size [d x Npts]
%                 where d is the dimensionality of the data and Npts is
%                 the number of data points.
%
%     adj_mat   - Graph adjucency matrix of data set. It is used when
%                 sampling in the way that only a complete subgraph is 
%                 sampled.
%
%     fittingfn - Handle to a function that fits a model to s
%                 data from x.  It is assumed that the function is of the
%                 form: 
%                    M = fittingfn(x)
%                 Note it is possible that the fitting function can return
%                 multiple models (for example up to 3 fundamental matrices
%                 can be fitted to 7 matched points).  In this case it is
%                 assumed that the fitting function returns a cell array of
%                 models.
%                 If this function cannot fit a model it should return M as
%                 an empty matrix.
%
%     distfn    - Handle to a function that evaluates the
%                 distances from the model to data x.
%                 It is assumed that the function is of the form:
%                    [inliers, M] = distfn(M, x, t)
%                 This function must evaluate the distances between points
%                 and the model returning the indices of elements in x that
%                 are inliers, that is, the points that are within distance
%                 't' of the model.  Additionally, if M is a cell array of
%                 possible models 'distfn' will return the model that has the
%                 most inliers.  If there is only one model this function
%                 must still copy the model to the output.  After this call M
%                 will be a non-cell object representing only one model. 
%
%     degenfn   - Handle to a function that determines whether a
%                 set of datapoints will produce a degenerate model.
%                 This is used to discard random samples that do not
%                 result in useful models.
%                 It is assumed that degenfn is a boolean function of
%                 the form: 
%                    r = degenfn(x)
%                 It may be that you cannot devise a test for degeneracy in
%                 which case you should write a dummy function that always
%                 returns a value of 1 (true) and rely on 'fittingfn' to return
%                 an empty model should the data set be degenerate.
%
%     s         - The minimum number of samples from x required by
%                 fittingfn to fit a model.
%
%     t         - The distance threshold between a data point and the model
%                 used to decide whether the point is an inlier or not.
%
%     feedback  - An optional flag 0/1. If set to one the trial count and the
%                 estimated total number of trials required is printed out at
%                 each step.  Defaults to 0.
%
%     maxDataTrials - Maximum number of attempts to select a non-degenerate
%                     data set. This parameter is optional and defaults to 100.
%
%     maxTrials - Maximum number of iterations. This parameter is optional and
%                 defaults to 1000.
%
% Returns:
%     M         - The model having the greatest number of inliers.
%     inliers   - An array of indices of the elements of x that were
%                 the inliers for the best model.
%
%
% Note that the desired probability of choosing at least one sample free from
% outliers is set at 0.99.  You will need to edit the code should you wish to
% change this (it should probably be a parameter)
%
% For an example of the use of this function see RANSACFITHOMOGRAPHY or
% RANSACFITPLANE 

% References:
%    M.A. Fishler and  R.C. Boles. "Random sample concensus: A paradigm
%    for model fitting with applications to image analysis and automated
%    cartography". Comm. Assoc. Comp, Mach., Vol 24, No 6, pp 381-395, 1981
%
%    Richard Hartley and Andrew Zisserman. "Multiple View Geometry in
%    Computer Vision". pp 101-113. Cambridge University Press, 2001

% Copyright (c) 2003-2013 Peter Kovesi
% Centre for Exploration Targeting
% The University of Western Australia
% peter.kovesi at uwa edu au    
% http://www.csse.uwa.edu.au/~pk
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in 
% all copies or substantial portions of the Software.
%
% The Software is provided "as is", without warranty of any kind.
%
% May      2003 - Original version
% February 2004 - Tidied up.
% August   2005 - Specification of distfn changed to allow model fitter to
%                 return multiple models from which the best must be selected
% Sept     2006 - Random selection of data points changed to ensure duplicate
%                 points are not selected.
% February 2007 - Jordi Ferrer: Arranged warning printout.
%                               Allow maximum trials as optional parameters.
%                               Patch the problem when non-generated data
%                               set is not given in the first iteration.
% August   2008 - 'feedback' parameter restored to argument list and other
%                 breaks in code introduced in last update fixed.
% December 2008 - Octave compatibility mods
% June     2009 - Argument 'MaxTrials' corrected to 'maxTrials'!
% January  2013 - Separate code path for Octave no longer needed

function [M, inliers] = ransac_guided(x, fittingfn, distfn, degenfn, s, t, varargin)

    maxTrials = 1000;
    maxDataTrials = 100;
    feedback = 0;
    affinity = [];
    
    if nargin > 6
        i = 1;
        while i <= length(varargin)
            switch varargin{i}
                case 'MaxTrials'
                    maxTrials = varargin{i+1};
                case 'MaxDataTrials'
                    maxDataTrials = varargin{i+1};
                case 'Feedback'
                    maxDataTrials = varargin{i+1};
                case 'SamplesAffinity'
                    affinity = varargin{i+1};
            end
            i = i + 2;
        end
    end
    
    [rows, npts] = size(x);
    
    % Set valid samples in the case of when samples affinity matrix is of
    % size npts*npts*npts (triple consistency).
    if length(size(affinity)) == 3
        validSamples = zeros(nnz(affinity) ,3);
        j = 1;
        for i = 1 : npts
            [r, c] = find(affinity(:,:,i));
            len = length(r);
            validSamples(j : j+len-1, :) = [ones(len,1) * i, r, c];
            j = j + len;
        end
    end
                    
    p = 0.99;         % Desired probability of choosing at least one sample
                      % free from outliers (probably should be a parameter)

    bestM = NaN;      % Sentinel value allowing detection of solution failure.
    trialcount = 0;
    bestscore =  0;
    N = 1;            % Dummy initialisation for number of trials.
    
    while N > trialcount
%         disp(['N = ' num2str(N) ', trialcount = ' num2str(trialcount)]);
        
        % Select at random s datapoints to form a trial model, M.
        % In selecting these points we have to check that they are not in
        % a degenerate configuration.
        degenerate = 1;
        count = 1;
        
        while degenerate
            
            % Generate 3 random indicies in the range 1..npts
            if ~isempty(affinity)
                if length(size(affinity)) == 2
                    edge_on_3complete = (affinity ^ 2) & affinity;
                    [rows, cols] = find(edge_on_3complete);
                    edge_i = randi(length(rows));
                    node1 = rows(edge_i);
                    node2 = cols(edge_i);
                    common_neigh = find(affinity(node1, :) & affinity(node2, :));
                    node3 = common_neigh(randi(length(common_neigh)));
                    ind = [node1 node2 node3]';
                    
                elseif length(size(affinity)) == 3
                    ind = validSamples(randi(size(validSamples,1)), :)';
                    
                else
                    error('invalid size of samples affinity matrix');
                end
                
            else
                if ~exist('randsample', 'file')
                    ind = randomsample(npts, s);
                else
                    ind = randsample(npts, s);
                end
            end

            % Test that these points are not a degenerate configuration.
            degenerate = feval(degenfn, x(:,ind));
            
            if ~degenerate
                % Fit model to this random selection of data points.
                % Note that M may represent a set of models that fit the data in
                % this case M will be a cell array of models
                M = feval(fittingfn, x(:,ind));
                
                % Depending on your problem it might be that the only way you
                % can determine whether a data set is degenerate or not is to
                % try to fit a model and see if it succeeds.  If it fails we
                % reset degenerate to true.
                if isempty(M)
                    degenerate = 1;
                end
            end
            
            % Safeguard against being stuck in this loop forever
            count = count + 1;
            if count > maxDataTrials
                warning('Unable to select a nondegenerate data set');
                break
            end
        end
        
        % Once we are out here we should have some kind of model...
        % Evaluate distances between points and model returning the indices
        % of elements in x that are inliers.  Additionally, if M is a cell
        % array of possible models 'distfn' will return the model that has
        % the most inliers.  After this call M will be a non-cell object
        % representing only one model.
        [inliers, M] = feval(distfn, M, x, t);
        
        % Find the number of inliers to this model.
        ninliers = length(inliers);
        
        if ninliers > bestscore    % Largest set of inliers so far...
            bestscore = ninliers;  % Record data for this model
            bestinliers = inliers;
            bestM = M;
            
            % Update estimate of N, the number of trials to ensure we pick,
            % with probability p, a data set with no outliers.
            fracinliers =  ninliers/npts;
            pNoOutliers = 1 -  fracinliers^s;
            pNoOutliers = max(eps, pNoOutliers);  % Avoid division by -Inf
            pNoOutliers = min(1-eps, pNoOutliers);% Avoid division by 0.
            N = log(1-p)/log(pNoOutliers);
        end
        
        trialcount = trialcount+1;
        if feedback
            fprintf('trial %d out of %d         \r',trialcount, ceil(N));
        end

        % Safeguard against being stuck in this loop forever
        if trialcount > maxTrials
            warning( ...
            sprintf('ransac reached the maximum number of %d trials',...
                    maxTrials));
            break
        end
    end
    
    if feedback, fprintf('\n'); end
    
    if ~isnan(bestM)   % We got a solution
        M = bestM;
        inliers = bestinliers;
    else
        M = [];
        inliers = [];
        error('ransac was unable to find a useful solution');
    end
    
