classdef Measurement
    %MEASUREMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        image_index;
        feature_index;
        pos;
        
        point_index;
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
    end
    
end
