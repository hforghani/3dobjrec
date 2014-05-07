clearvars;

model_data_path = [get_dataset_path() '0-24(1)\0-24\anchiceratops\'];

model_data_f_name = 'data/model/anchiceratops';

load(model_data_f_name);

%% Show a camera and its points.
point_index = 871;
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
    
    Kc = model.get_Kc();
    point = Kc * [measurement.pos; 1];
    
    imshow(I);
    hold on;
    scatter(model.calibration.cx, model.calibration.cy, 100 , 'r+');
    scatter(point(1), point(2), 100 , 'y');
end
