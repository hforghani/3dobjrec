classdef Measurement
    %MEASUREMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        image_index;
        feature_index;
        pos;
        
        frames;
        descriptors;
    end
    
    properties (SetAccess = private)
        min_scale = 1.5;
        max_scale = 5;
        scale_step = 0.1;
    end
    
    methods
        function self = Measurement(image_index, feature_index, pos)
            self.image_index = image_index;
            self.feature_index = feature_index;
            self.pos = pos;
        end
        
        function pos = get_pos_in_camera(self, calibration)
            % Get point position in camera image.
            Kc = [1 0 calibration.cx; 0 calibration.fy/calibration.fx calibration.cy; 0 0 1];
            pos = Kc * [self.pos; 1];
            pos = pos(1:2);
        end
        
        function self = calc_descriptors(self, img_fold_name, model)
            % Calculate and save descriptors property.
            % f : keypoint frames.
            % d : keypoint descriptors.
            file_name = model.cameras{self.image_index}.file_name;
            im = imread([img_fold_name, file_name]);
            im_gray = single(rgb2gray(im));
            
            scale_range = self.min_scale : self.scale_step : self.max_scale;
            pos_in_camera = self.get_pos_in_camera(model.calibration);
            fr = [pos_in_camera; 0; 0];
            fr = repmat(fr, 1, length(scale_range));
            fr(3,:) = scale_range;

            [fr, de] = vl_sift(im_gray, 'frames', fr, 'orientations');
%             self.frames = f;
%             self.descriptors = d;
            
            self.descriptors = cell(length(scale_range),1);
            self.frames = cell(length(scale_range),1);
            for i = 1:length(scale_range)
                indexes = abs(fr(3,:) - scale_range(i)) < 0.001;
                self.frames{i} = fr(:, indexes);
                self.descriptors{i} = de(:, indexes);
            end
        end
    end
    
end
