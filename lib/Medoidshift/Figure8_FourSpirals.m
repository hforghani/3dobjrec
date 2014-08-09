noisep = 20;
x = 2*abs(randn(500,1));
x = [[-x.*sin(x)-0.5+randn(500,1)/noisep; x.*sin(x)-0.25+randn(500,1)/noisep; -x.*sin(x+1.5)-0.75+randn(500,1)/noisep; x.*sin(x+1.5)+randn(500,1)/noisep] ...
    [-x.*cos(x)+randn(500,1)/noisep; x.*cos(x)+0.25+randn(500,1)/noisep; -x.*cos(x+1.5)+0.25+randn(500,1)/noisep; x.*cos(x+1.5)+randn(500,1)/noisep]]';

ar_mode = ones(1,length(x));

sigma = 1;
D = dist(x).^2;

options.dims = 1:10;
[D_new] = IsomapIID(D, 'k', 9, options); %http://isomap.stanford.edu

% Single Iteration
[ar_mode,I,S,D,W] = medoidshiftIterative(D_new,NaN,sigma); % Step 1 of Medoidshift Algorithm (See paper)
visualizeClustering(ar_mode,x); % Visualize Result
title('Modes after a single iteration');

% Full medoidshift
[ar_mode2, iter] = medoidshift(D_new,sigma); % Complete Medoidshift Algorithm
visualizeClustering(ar_mode2,x); % Visualize Result
title(sprintf('Medoidshift Result: %d Iterations',iter));