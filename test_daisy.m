clearvars;
addpath daisy;
im = imread('test/test2.jpg');
im = single(rgb2gray(im));

dzy = compute_daisy(im);
out = display_descriptor(dzy,100,100);
