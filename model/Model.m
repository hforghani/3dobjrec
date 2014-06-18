classdef Model
    %MODEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        calibration;
        cameras;
        points;

        point_sizes;
        descriptors;
        desc_point_indexes;
        kdtree;
    end
    
    methods
        function obj = Model(calibration, cameras, points)
            obj.calibration = calibration;
            obj.cameras = cameras;
            obj.points = points;
        end
        
        function self = calc_multi_desc(self, model_path)
            fprintf('Calculating descriptors in %d cameras ...\n', length(self.cameras));
            for i = 1:length(self.cameras)
%                 tic;
                cam = self.cameras{i};
                cam = cam.calc_desc(self.points, model_path);
                self.cameras{i} = cam;
%                 toc;
            end
        end
    
        function trans_points3d = trans_to_cam_coord(self, R, C)
        % Transform points to camera coordinates specified by R and C.
        % R : camera rotation
        % C : camera center
            points_count = length(self.points);
            poses = self.get_poses();
            trans_points3d = R * poses + repmat(C, 1, points_count);
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
                
                K = self.calibration.get_calib_matrix();
                pos2d = K * transformed;
                points2d(:,i) = pos2d(1:2) / pos2d(3);
            end
        end
        
        function poses = get_poses(self)
            points_count = length(self.points);
            poses = zeros(3, points_count);
            for i = 1:points_count
                poses(:, i) = self.points{i}.pos;
            end
        end
        
        function colors = get_colors(self)
            points_count = length(self.points);
            colors = zeros(3, points_count);
            for i = 1:points_count
                colors(:, i) = self.points{i}.color;
            end
        end
    end
    
end
