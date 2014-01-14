classdef Model
    %MODEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        calibration;
        cameras;
        points;
    end
    
    methods
        function obj = Model(calibration, cameras, points)
            obj.calibration = calibration;
            obj.cameras = cameras;
            obj.points = points;
        end
    end
    
end
