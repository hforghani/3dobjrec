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
        singlescale_desc;
        single_desc_point_indexes;
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
        
        function self = calc_multi_desc(self, model, model_path)
            measurements = self.get_measurements(model);

%             % Create frames matrix.
%             scale_range = self.min_scale : self.scale_step : self.max_scale;
%             scale_count = length(scale_range);
%             frames = zeros(4,length(measurements) * scale_count);
%             point_indexes = zeros(1, size(frames,2));
%             for i = 1:length(measurements)
%                 begin = (i-1) * scale_count + 1;
%                 ending = i * scale_count;
%                 meas_pos = measurements{i}.get_pos_in_camera(model.calibration);
%                 frames(1:2, begin:ending) = repmat(meas_pos, 1, length(scale_range));
%                 frames(3, begin:ending) = scale_range;
%                 point_indexes(begin:ending) = measurements{i}.point_index;
%             end
% 
            im_gray = single(rgb2gray(self.get_image(model_path)));
%             [res_frames, desc] = vl_sift(im_gray, 'frames', frames, 'orientations');
%             
%             % Update point indexes because of new columns for orientations.
%             new_p_indexes = zeros(1, size(res_frames,2));
%             for i = 1 : scale_count : size(frames,2)
%                 have_equal_pos = abs(res_frames(1,:) - frames(1,i)) < 0.0001 ...
%                     & abs(res_frames(2,:) - frames(2,i)) < 0.0001;
%                 new_p_indexes(have_equal_pos) = point_indexes(i);
%             end
% 
%             self.multiscale_desc = desc;
%             self.multi_desc_point_indexes = new_p_indexes;
            
            
            self.multiscale_desc = zeros(200, length(measurements));
            self.multi_desc_point_indexes = zeros(1, length(measurements));
            for i = 1:length(measurements)
                meas_pos = measurements{i}.get_pos_in_camera(model.calibration);
                x = meas_pos(1);
                y = meas_pos(2);
                x1 = max(1, x-50);
                x2 = min(size(im_gray,2), x+50);
                y1 = max(1, y-50);
                y2 = min(size(im_gray,1), y+50);
                dzy = compute_daisy(im_gray(y1 : y2, x1 : x2));
                desc = display_descriptor(dzy, x - x1, y - y1);
                self.multiscale_desc(:,i) = reshape(desc, 200, 1);
                self.multi_desc_point_indexes(i) = measurements{i}.point_index;
            end
            
            self.desc_kdtree = vl_kdtreebuild(double(self.multiscale_desc)) ;
            
            fprintf('Multi-scale descriptor of cemera %d with %d measurements calculated.\n', self.index, length(measurements));
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
