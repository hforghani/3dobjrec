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
        
        function Kc = get_Kc(self)
            % Multiply to convert 2d image pose to 2d pixel position.
            cal = self.calibration;
            Kc = [1 0 cal.cx; 0 cal.fy/cal.fx cal.cy; 0 0 1];
        end
        
        function K = get_calib_matrix(self)
            % Multiply to convert 3d pose to 2d pose.
            cal = self.calibration;
            K = [cal.fx 0 cal.cx; 0 cal.fy cal.cy; 0 0 1];
        end
        
        function self = calc_multi_desc(self, model_path)
            fprintf('Calculating descriptors in %d cameras began.\n', length(self.cameras));
            for i = 1:length(self.cameras)
%                 tic;
                cam = self.cameras{i};
                cam = cam.calc_multi_desc(self, model_path);
                self.cameras{i} = cam;
%                 toc;
            end
        end
    
%         function self = calc_single_desc(self, scale, model_path)
%             fprintf('Calculating descriptors in %d cameras began.\n', length(self.cameras));
%             for i = 1:length(self.cameras)
% %                 tic;
%                 cam = self.cameras{i};
%                 cam = cam.calc_single_desc(scale, self, model_path);
%                 self.cameras{i} = cam;
% %                 toc;
%             end
%         end

        function trans_points3d = transform_points(self, R, T)
            points_count = length(self.points);
            trans_points3d = zeros(3, points_count);
            for i = 1:points_count
                pos3d = self.points{i}.pos;
                transformed = R * pos3d + T;
                trans_points3d(:,i) = transformed;
            end
        end

        function points2d = project_points(self, R, T)
            points_count = length(self.points);
            points2d = zeros(2, points_count);
            points3d = zeros(3, points_count);
            proj_points3d = zeros(3, points_count);
            for i = 1:points_count
                pos3d = self.points{i}.pos;
                transformed = R * pos3d + T;
                proj_points3d(:,i) = transformed;
                points3d(:,i) = pos3d;
                
                K = self.get_calib_matrix();
                pos2d = K * transformed;
                points2d(:,i) = pos2d(1:2) / pos2d(3);
            end
        end
    end
    
end
