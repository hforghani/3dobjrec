function [pts] = randcrescent(n,r,theta,offset,sigma, circSigma)
% Creates 2D random samples in the shape of a crescent
% [pts] = randcrescent(n,r,theta,offset,sigma,circSigma)
% n: number of samples
% r: radius 
% theta:
% offset: offset
% circSigma: Spread on the circle

theta2 = theta+randn(1,n)/circSigma;
pts(1,:) = r*cos(theta2)+randn(1,n)/sigma+offset(1);
pts(2,:) = r*sin(theta2)+randn(1,n)/sigma+offset(2);
