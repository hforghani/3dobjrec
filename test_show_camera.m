close all;

model_path = [get_dataset_path() '0-24(1)\0-24\anchiceratops\'];
model_fname = [model_path 'model.nvm'];
model = read_model(model_fname);
points_num = length(model.points);

%% Show a camera and its points.
indexes = [1 50 75 200];
plot_id = 1;
for image_index = indexes
    features = [];

    for i = 1:points_num
        point = model.points{i};
        for j = 1:point.measure_num
            mesurement_j = point.measurements{j};
            if mesurement_j.image_index == image_index
                features = [features mesurement_j.pos];
            end
        end
    end

    file_name = model.cameras{image_index}.file_name;
    I = imread([model_path 'db_img\' file_name]);
    [height, width, ~] = size(I);
    f_num = size(features, 2);
    cal = model.calibration;
    center = [cal.cx; cal.cy];
    Kc = [1 0 cal.cx; 0 cal.fy/cal.fx cal.cy; 0 0 1];
    features = Kc * [features; ones(1,f_num)];
    subplot(2,2,plot_id);
    plot_id = plot_id + 1;
    imshow(I);
    hold on;
    scatter(center(1), center(2), 100 , 'r+');
    scatter(features(1,:), features(2,:), ones(1,f_num)*20 , 'y');
end
