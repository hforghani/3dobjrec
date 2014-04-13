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
        multiscale_desc;
        multi_desc_point_indexes;
        desc_kdtree;
    end
    
    properties (SetAccess = private)
        min_scale = 1.5;
        max_scale = 5;
        scale_step = 0.1;
    end
    
    methods
        function obj = Camera(file_name, focal_length, q_rotation, center, r_distortion)
            obj.file_name = file_name;
            obj.focal_length = focal_length;
            obj.q_rotation = q_rotation;
            obj.center = center;
            obj.r_distortion = r_distortion;
        end
        
        function self = calc_multi_desc(self, points, calibration, model_path)
            im_gray = single(rgb2gray(self.get_image(model_path)));
            measurements = self.get_measurements(points);
            meas_poses = zeros(2, length(measurements));
            self.multi_desc_point_indexes = zeros(1, length(measurements));
            for i = 1:length(measurements)
                meas_poses(:,i) = measurements{i}.get_pos_in_camera(calibration);
                self.multi_desc_point_indexes(i) = measurements{i}.point_index;
            end
            self.multiscale_desc = devide_and_compute_daisy(im_gray, meas_poses);
            self.desc_kdtree = vl_kdtreebuild(double(self.multiscale_desc));
            
            fprintf('Descriptors of cemera %d with %d measurements calculated.\n', self.index, length(measurements));
        end
        
        function measurements = get_measurements(self, points)
            measurements = {};
            for i = 1:length(points)
                pt = points{i};
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
