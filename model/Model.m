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
        
        function self = calc_multiscale_descriptors(self, model_path)
            N = size(self.points, 1);
            for i = 1:N
                tic;
                point = self.points{i}.calc_multiscale_descriptors([model_path 'db_img\'], self);
                self.points{i} = point;
                fprintf('Point %d with %d measurements prepared.\n', i, self.points{i}.measure_num);
                toc;
                if mod(i, 100) == 0
                    save model;
                end
            end
        end

        function self = calc_descriptor(self, model_path)
            N = size(self.points, 1);
            for i = 1:N
                tic;
                point = self.points{i}.calc_descriptor([model_path 'db_img\'], self);
                self.points{i} = point;
                fprintf('Point %d with %d measurements prepared.\n', i, self.points{i}.measure_num);
                toc;
                if mod(i, 100) == 0
                    save model;
                end
            end
        end
    end
    
end
