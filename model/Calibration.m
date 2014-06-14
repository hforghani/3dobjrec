classdef Calibration
    %CALIBRATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fx;
        cx
        fy;
        cy;
    end
    
    methods
        function obj = Calibration(fx, cx, fy, cy)
            obj.fx = fx;
            obj.cx = cx;
            obj.fy = fy;
            obj.cy = cy;
        end
        
        function Kc = get_Kc(self)
            % Multiply to convert 2d image pose to 2d pixel position.
            Kc = [1 0 self.cx; 0 self.fy/self.fx self.cy; 0 0 1];
        end
        
        function K = get_calib_matrix(self)
            % Multiply to convert 3d pose to 2d pose.
            K = [self.fx 0 self.cx; 0 self.fy self.cy; 0 0 1];
        end
        
    end
    
end

