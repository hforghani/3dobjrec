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
    end
    
end

