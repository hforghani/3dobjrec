% Simple example to tool around with
% Two Gaussian distributions of sigma = 1, centered on (0,0) and (5,5)
% Results for one iteration and for the complete algorithm are shown

clear;
npts = 300; % Number of samples in each Distribution

x = [randn(2,npts) randn(2,npts)+5]; % Create Dataset

sigma = 1; % BandWidth
figure, plot(x(1,:),x(2,:),'r.'); axis equal; title('Raw Data'); box on; grid on;
D  = dist(x).^2; % Compute Distance Matrix

% Single Iteration
[ar_mode,I,S,D,W] = medoidshiftIterative(D,NaN,sigma); % Step 1 of Medoidshift Algorithm (See paper)
visualizeClustering(ar_mode,x); % Visualize Result
title('Modes after a single iteration');

% Full medoidshift
[ar_mode2, iter] = medoidshift(D,sigma); % Complete Medoidshift Algorithm
visualizeClustering(ar_mode2,x); % Visualize Result
title(sprintf('Medoidshift Result: %d Iterations',iter));