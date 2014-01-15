classdef Measurement
    %MEASUREMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        image_index;
        feature_index;
        pos;
        
        multiscale_desc;
    end
    
    properties (SetAccess = private)
        min_scale = 1.5;
        max_scale = 5;
        scale_step = 0.1;
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
        
        function self = calc_descriptors(self, img_fold_name, model)
            % Calculate and save descriptors property.
            % img_fold_name : folder if camera images in dataset.
            % model: model class of dataset.
            file_name = model.cameras{self.image_index}.file_name;
            im = imread([img_fold_name, file_name]);
            im_gray = single(rgb2gray(im));
            
            pos_in_camera = self.get_pos_in_camera(model.calibration);
            self.multiscale_desc = self.calc_desc_in_scales(im_gray, pos_in_camera);
        end
        
        function [f, d, min_dist] = get_best_multiscale_match(self, desc)
            % Get best matching descriptor between all descriptor pairs of
            % this multi-scale descriptor and the multi-scale descriptor given.
            % desc : an instance of MultiscaleDescriptor.
            % f : best matched frame.
            % d : best matched descriptor.
            % min_dist: minimum distance.
            scales_size = size(self.frames_array, 1);
            min_dist = -1;
            f = []; d = [];
            for s = 1 : scales_size
                self_desc = self.descriptors_array{s};
                other_desc = desc.descriptors_array{s};
                for self_i = 1 : size(self_desc, 2)
                    for other_i = 1 : size(other_desc, 2)
                        dist = norm(double(self_desc(:,self_i) - other_desc(:,other_i)));
                        if min_dist == -1 || dist < min_dist
                            min_dist = dist;
                            d = self_desc(:,self_i);
                            f = self.frames_array{s}(:,self_i);
                        end
                    end
                end
            end
        end
        
        function [f, d, min_dist] = get_best_match(self, frame, desc)
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
            index = length(scales);
            for i = 1:length(scales)
                if scales(i) - scale <= self.scale_step / 2
                    index = i;
                    break;
                end
            end
        end
    end
    
end
