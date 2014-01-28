clearvars; close all;
addpath EPnP;

matches_f_name = 'data/matches_anchiceratops';

matches = load(matches_f_name);
matches2d = matches.matches2d;
matches3d = matches.matches3d;
match_count = size(matches2d,2);

% [M, inliers] = ransac(x, fittingfn, distfn, degenfn ,s, t);