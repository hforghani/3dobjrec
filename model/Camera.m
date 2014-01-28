classdef Camera
    %CAMERA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        file_name;
        focal_length;
        q_rotation;
        center;
        r_distortion;
        
        index;
        singlescale_desc
    end
    
    methods
        function obj = Camera(file_name, focal_length, q_rotation, center, r_distortion)
            obj.file_name = file_name;
            obj.focal_length = focal_length;
            obj.q_rotation = q_rotation;
            obj.center = center;
            obj.r_distortion = r_distortion;
        end
        
        function self = calc_single_desc(self, scale, model, model_path)
            measurements = self.get_measurements(model);

            frames = zeros(4,length(measurements));
            for j = 1:length(measurements)
                frames(1:2,j) = measurements{j}.get_pos_in_camera(model.calibration);
            end
            frames(3,:) = scale;

            im_gray = single(rgb2gray(self.get_image(model_path)));
            [~, desc] = vl_sift(im_gray, 'frames', frames);
            self.singlescale_desc = desc;
            
            fprintf('Single descriptor of cemera %d with %d measurements calculated.\n', self.index, length(measurements));
        end
        
        function measurements = get_measurements(self, model)
            measurements = {};
            for i = 1:length(model.points)
                pt = model.points{i};
                for j = 1:length(pt.measurements)
                    meas = pt.measurements{j};
                    if meas.image_index == self.index
                        measurements = [measurements {meas}];
                    end
                end
            end
        end
        
        function im = get_image(self, model_path)
            im = imread([model_path 'db_img\' self.file_name]);
        end
        
    end
    
end
