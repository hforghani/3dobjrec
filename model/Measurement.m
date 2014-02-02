classdef Measurement
    %MEASUREMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        image_index;
        feature_index;
        pos;
        
        multiscale_desc;
        singlescale_desc;
        point_index;
    end
    
    properties (SetAccess = private)
        min_scale = 1.5;
        max_scale = 5;
        scale_step = 0.1;
        
        single_scale = 1.2;
    end
    
    methods
        function self = Measurement(varargin)
            if nargin == 3
                self.image_index = varargin{1};
                self.feature_index = varargin{2};
                self.pos = varargin{3};
            end
        end
        
        function pos = get_pos_in_camera(self, calibration)
            % Get point position in camera image.
            Kc = [1 0 calibration.cx; 0 calibration.fy/calibration.fx calibration.cy; 0 0 1];
            pos = Kc * [self.pos; 1];
            pos = pos(1:2);
        end
        
        function self = calc_multiscale_descriptors(self, img_fold_name, model)
            % Calculate and save descriptors property.
            % img_fold_name : folder if camera images in dataset.
            % model: model class of dataset.
            file_name = model.cameras{self.image_index}.file_name;
            im = imread([img_fold_name, file_name]);
            im_gray = single(rgb2gray(im));
            
            pos_in_camera = self.get_pos_in_camera(model.calibration);
            self.multiscale_desc = self.calc_desc_in_scales(im_gray, pos_in_camera);
        end
        
        function multiscale_desc = calc_desc_in_scales(self, image, im_pos)
            % Calculate sift descriptors in a range of scales.
            % image: gray-scale image
            % im_pos: position of the point in the image
            % fr_array: cell array of frames of size length(scale_range)
            % fr_array: cell array of descriptors of size length(scale_range)
            
            scale_range = self.min_scale : self.scale_step : self.max_scale;
            fr = [im_pos; 0; 0];
            fr = repmat(fr, 1, length(scale_range));
            fr(3,:) = scale_range;

            [fr, de] = vl_sift(image, 'frames', fr, 'orientations');
            
            fr_array = cell(length(scale_range),1);
            de_array = cell(length(scale_range),1);
            for i = 1:length(scale_range)
                indexes = abs(fr(3,:) - scale_range(i)) < 0.001;
                fr_array{i} = fr(:, indexes);
                de_array{i} = de(:, indexes);
            end
            multiscale_desc = MultiscaleDescriptor(fr_array, de_array);
        end
        
        function [d, min_dist] = get_best_match_to_singlescale(self, desc)
            % Get distance of the descriptor given to the single-scale
            % descriptor of self.
            % desc : descriptor
            % dist: distance;
            min_dist = -1;
            d = [];
            self_desc = self.singlescale_desc;
            for self_i = 1 : size(self_desc, 2)
                for other_i = 1 : size(desc, 2)
                    dist = norm(double(self_desc(:,self_i) - desc(:,other_i)));
                    if min_dist == -1 || dist < min_dist
                        min_dist = dist;
                        d = self_desc(:,self_i);
                    end
                end
            end
        end
        
        function [f, d, min_dist] = get_best_match_to_multiscale(self, frame, desc)
            % Get best matching descriptor between all descriptor pairs of
            % this multi-scale descriptor and the descriptor given.
            % frame: sift frame
            % desc: sift descriptor
            given_scale = frame(3);
            min_dist = -1;
            f = []; d = [];
            s_index = self.get_nearest_scale_index(given_scale);
            self_desc = self.multiscale_desc.descriptors_array{s_index};
            for self_i = 1 : size(self_desc, 2)
                for other_i = 1 : size(desc, 2)
                    dist = norm(double(self_desc(:,self_i) - desc(:,other_i)));
                    if min_dist == -1 || dist < min_dist
                        min_dist = dist;
                        d = self_desc(:,self_i);
                        f = self.multiscale_desc.frames_array{s_index}(:,self_i);
                    end
                end
            end
        end
        
        function index = get_nearest_scale_index(self, scale)
            scales = self.min_scale : self.scale_step : self.max_scale;
            index = -1;
            for i = 1:length(scales)
                if abs(scales(i) - scale) <= self.scale_step / 2
                    index = i;
                    break;
                end
            end
            if index == -1
                if scale > self.max_scale
                    index = length(scales);
                else
                    index = 1;
                end
            end
        end
    end
    
end
