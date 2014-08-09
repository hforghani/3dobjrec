% Two Spiraling distributions
% Results for one iteration and for the complete algorithm are shown

x = 2*abs(randn(500,1)); x = 2*abs(randn(500,1)); 
x = [-[x.*sin(x)]' [x.*sin(x)]'-1; -[x.*cos(x)]' [x.*cos(x)]'+1; -randn(500,1)' -randn(500,1)'];

figure, plot3(x(1,:),x(2,:),x(3,:),'r.'); axis equal; title('Raw Data'); box on; grid on; % Use Rotate3D Button to explore data

sigma = 5;

D = dist(x).^2;
options.dims = 1:10;
[D_new] = IsomapIID(D, 'k', 7, options); % Modified code from http://isomap.stanford.edu/

% Single Iteration
[ar_mode,I,S,D,W] = medoidshiftIterative(D_new,NaN,sigma); % Step 1 of Medoidshift Algorithm (See paper)
visualizeClustering(ar_mode,x); % Visualize Result
title('Modes after a single iteration');
view(-45,70);

% Full medoidshift
[ar_mode2, iter] = medoidshift(D_new,sigma); % Complete Medoidshift Algorithm
visualizeClustering(ar_mode2,x); % Visualize Result
title(sprintf('Medoidshift Result: %d Iterations',iter));
view(-45,70);