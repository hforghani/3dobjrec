clearvars;

model_data_path = [get_dataset_path() '0-24(1)\0-24\anchiceratops\'];
model_data_f_name = 'data/model_ankylosaurus_brown_multi.mat';

model_fname = [model_data_path 'model.nvm'];
load(model_data_f_name);

%% Show a camera and its points.
point_index = 1001;
pt = model.points{point_index};

figure(1);
% Iterate on measurements.
for measure_i = 1:6
    subplot(2,3,measure_i);
    if measure_i > pt.measure_num
        imshow(ones(size(I)),[0 1]);
        continue
    end
    measurement = pt.measurements{measure_i};
    image_index = measurement.image_index;    
    file_name = model.cameras{image_index}.file_name;
    I = imread([model_data_path 'db_img\' file_name]);
    
    cal = model.calibration;
    Kc = [1 0 cal.cx; 0 cal.fy/cal.fx cal.cy; 0 0 1];
    point = Kc * [measurement.pos; 1];
    
    imshow(I);
    hold on;
    scatter(cal.cx, cal.cy, 100 , 'r+');
    scatter(point(1), point(2), 100 , 'y');
end
