clearvars;
addpath daisy;
im = imread('test/test2.jpg');
gray_im = single(rgb2gray(im));
dzy = compute_daisy(gray_im);
out = display_descriptor(dzy,100,100);
