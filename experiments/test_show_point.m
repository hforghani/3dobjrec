function test_show_point(obj_name, point_index)

    model_data_path = [get_dataset_path() obj_name '\'];

    model_data_f_name = ['data/model/' obj_name];

    load(model_data_f_name);

    %% Show a camera and its points.
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
        I = model.cameras{image_index}.get_image(model_data_path);
        point = model.calibration.get_Kc() * [measurement.pos; 1];

        imshow(I);
        hold on;
        scatter(model.calibration.cx, model.calibration.cy, 100 , 'r+');
        scatter(point(1), point(2), 100 , 'y');
    end
end
