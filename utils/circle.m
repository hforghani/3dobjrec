function circle(ox, oy, r)

numPoints = 100 * r; %Number of points making up the circle

%Define circle in polar coordinates (angle and radius)
theta = linspace(0, 2*pi, numPoints); %100 evenly spaced points between 0 and 2pi
rho = ones(1, numPoints) * r; %Radius should be 1 for all 100 points

%Convert polar coordinates to Cartesian for plotting
[X,Y] = pol2cart(theta,rho);
X = X + ones(1, numPoints) * ox;
Y = Y + ones(1, numPoints) * oy;


%Plot a red circle
plot(X, Y, 'b-');

end