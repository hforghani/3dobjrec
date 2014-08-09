% Five Crescent Distributions
% Results for one iteration and for the complete algorithm are shown

clear;
npts = 600;

[pts1] = randcrescent(npts,5,pi,[3 1],1, 1.8);
[pts2] = randcrescent(npts,25,-2*pi,[-9 9],1, 2.5);
[pts3] = randcrescent(npts,10,-3/2*pi,[-10 11],1, 1.8);
[pts4] = randcrescent(npts,10,-0.5*pi,[-20 10],1, 1.8);
[pts5] = randcrescent(npts,20,-pi,[-20 10],1, 2);

x = [pts1 pts2 pts3 pts4 pts5];

sigma = 10; % BandWidth
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