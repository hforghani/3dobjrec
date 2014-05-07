classdef Point
    %POINT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        pos;
        color;
        measure_num;
        measurements;
        
        descriptor;
    end
    
    methods
        function self = Point(pos, color, measure_num, measurements)
            self.pos = pos;
            self.color = color;
            self.measure_num = measure_num;
            self.measurements = measurements;
        end
        
        function self = calc_multiscale_descriptors(self, img_fold_name, model)
            for i = 1:self.measure_num
                self.measurements{i} = self.measurements{i}.calc_multiscale_descriptors(img_fold_name, model);
            end
        end
        
        function res = is_covisible_with(self, points)
            % Return a matrix which each cell of it indicates whether the 
            % point is co-visible with this point in any camera. points is
            % an array of Point.
            self_cam_indexes = zeros(self.measure_num, 1);
            for i = 1:self.measure_num
                self_cam_indexes(i) = self.measurements{i}.image_index;
            end
            res = zeros(length(points), 1);
            for i = 1:length(points)
                pnt = points{i};
                point_cam_indexes = zeros(pnt.measure_num, 1);
                for j = 1:pnt.measure_num
                    point_cam_indexes(j) = pnt.measurements{j}.image_index;
                end
                res(i) = ~isempty(intersect(self_cam_indexes, point_cam_indexes));
            end
            res = logical(res);
        end
        
        function show_measurements(self, model, model_data_path)
            % Show up to 6 measurements in their camera images.
            figure(2);
            % Iterate on measurements.
            for measure_i = 1:6
                subplot(2,3,measure_i);
                if measure_i > self.measure_num
                    imshow(ones(size(I)),[0 1]);
                    continue
                end
                measurement = self.measurements{measure_i};
                image_index = measurement.image_index;    
                file_name = model.cameras{image_index}.file_name;
                I = imread([model_data_path 'db_img\' file_name]);

                cal = model.calibration;
                Kc = model.get_Kc();
                point = Kc * [measurement.pos; 1];

                imshow(I);
                hold on;
                scatter(cal.cx, cal.cy, 100 , 'r+');
                scatter(point(1), point(2), 100 , 'y');
%                 zoom(2);
            end
        end
    end
    
end
