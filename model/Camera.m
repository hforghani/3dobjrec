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
    end
    
    methods
        function obj = Camera(file_name, focal_length, q_rotation, center, r_distortion)
            obj.file_name = file_name;
            obj.focal_length = focal_length;
            obj.q_rotation = q_rotation;
            obj.center = center;
            obj.r_distortion = r_distortion;
        end
        
        function R = rotation_matrix(self)
            R = quaternion2matrix(self.q_rotation);
            R = R(1:3, 1:3);
        end
        
        function [descriptors, desc_point_indexes] = calc_desc(self, points, calibration, model_path)
            % Calculate Daisy descriptors of points visible in the camera.
            im_gray = single(rgb2gray(self.get_image(model_path)));
            [meas_poses, measurements] = self.get_points_poses(points, calibration);
            desc_point_indexes = zeros(1, length(measurements));
            for i = 1:length(measurements)
                desc_point_indexes(i) = measurements{i}.point_index;
            end
            descriptors = devide_and_compute_daisy(im_gray, meas_poses);
            
            fprintf('Descriptors of cemera %d with %d measurements calculated.\n', self.index, length(measurements));
        end
        
        function scales = calc_scales(self, points, calibration, model_path)
            % Caluclate scales. Extract SIFT and get scale of nearest
            % neighbor feature to each pose as its estimated scale. Crop
            % the portion of image in which poses exist to extract SIFT.
            im_gray = single(rgb2gray(self.get_image(model_path)));
            [meas_poses, ~] = self.get_points_poses(points, calibration);
            
            frames = vl_covdet(im_gray, 'Method', 'DoG', 'Frames', meas_poses);
            scales = mean([frames(3,:); frames(6,:)]);
        end
        
        function measurements = get_measurements(self, points)
            % Get measurements visible in the camera.
            % points is the array of all points.
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
        
        function [poses, measurements] = get_points_poses(self, points, calibration)
        % Get 2d poses of measurements visible in the camera.
        % poses : 2*N matrix of poses
        % measurements : 1*N cell array of measurements.
            measurements = {};
            poses = [];
            for i = 1:length(points)
                pt = points{i};
                for j = 1:length(pt.measurements)
                    meas = pt.measurements{j};
                    if meas.image_index == self.index
                        poses = [poses, meas.pos];
                        measurements = [measurements {meas}];
                    end
                end
            end
            f_num = size(poses, 2);
            poses = calibration.get_Kc * [poses; ones(1,f_num)];
            poses = poses(1:2, :);
        end
        
        function im = get_image(self, model_path)
            im = imread([model_path 'db_img\' self.file_name]);
        end
        
    end
    
end
