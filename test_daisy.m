clearvars; close all;
addpath daisy;

%% Compute DAISY of an arbitrary point.
% im = imread('test/test2.jpg');
% im = double(rgb2gray(im));
% dzy = compute_daisy(im);
% out = display_descriptor(dzy,100,100);

%% Compare DAISY of measurements of a 3d point.
model_f_name = 'data/model_anchi_daisy_kd';
point_index = 1000;

model = load(model_f_name);
model = model.model;
pt = model.points{point_index};
descriptors = zeros(200, pt.measure_num);
for i = 1 : pt.measure_num
    measurement = pt.measurements{i};
    cam_index = measurement.image_index;    
    cam = model.cameras{cam_index};
    meas_desc = cam.multiscale_desc(:, cam.multi_desc_point_indexes == point_index);
    descriptors(:,i) = meas_desc;
end
cov = cov(descriptors')
