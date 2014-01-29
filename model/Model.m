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
        
        function Kc = get_intrinsic_matrix(self)
            cal = self.calibration;
            Kc = [1 0 cal.cx; 0 cal.fy/cal.fx cal.cy; 0 0 1];
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

%         function self = calc_descriptor(self, model_path)
%             N = size(self.points, 1);
%             for i = 1:N
%                 tic;
%                 point = self.points{i}.calc_descriptor([model_path 'db_img\'], self);
%                 self.points{i} = point;
%                 fprintf('Point %d with %d measurements prepared.\n', i, self.points{i}.measure_num);
%                 toc;
%                 if mod(i, 100) == 0
%                     save model;
%                 end
%             end
%         end
        
        function self = calc_single_desc(self, scale, model_path)
            for i = 1:length(self.cameras)
%                 tic;
                cam = self.cameras{i};
                cam = cam.calc_single_desc(scale, self, model_path);
                self.cameras{i} = cam;
%                 toc;
                if mod(i, 10) == 0
                    save model;
                end
            end
        end
        
        function points2d = project_points(self, R, T)
            points_count = length(self.points);
            points2d = zeros(2, points_count);
            points3d = zeros(3, points_count);
            proj_points3d = zeros(3, points_count);
            for i = 1:points_count
                pos3d = self.points{i}.pos;
                projected = R * pos3d + T;
                proj_points3d(:,i) = projected;
                points3d(:,i) = pos3d;
                
                Kc = self.get_intrinsic_matrix();
                K = [self.calibration.fx 0 0; 0 self.calibration.fx 0; 0 0 1];
                pos2d = Kc * K * projected;
                points2d(:,i) = pos2d(1:2);
            end
        end
    end
    
end
