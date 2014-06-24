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
        
        function res_points = transform_points(self, R, T)
        % Transform points by R and T.
        % R : rotation matrix
        % T : translation matrix
            points_count = length(self.points);
            poses = self.get_poses();
            res_points = R * poses + repmat(T, 1, points_count);
        end

        function trans_points3d = trans_to_cam_coord(self, R, T)
        % Transform points to camera coordinates specified by R and T.
        % R : world to camera rotation
        % T : camera center in world coordinates
            trans_points3d = self.transform_points(R, -R*T);
        end

        function points2d = project_to_img_plane(self, R, T)
            % Project points to image plane of given camera.
            % R : world to camera rotation
            % T : world to camera translation
%             points_count = length(self.points);
%             points2d = zeros(2, points_count);
%             points3d = zeros(3, points_count);
%             for i = 1:points_count
%                 pos3d = self.points{i}.pos;
%                 transformed = R * pos3d + T;
%                 points3d(:,i) = pos3d;
%                 
%                 K = self.calibration.get_calib_matrix();
%                 pos2d = K * transformed;
%                 points2d(:,i) = pos2d(1:2) / pos2d(3);
%             end
            pos3d = self.transform_points(R, T);
            K = self.calibration.get_calib_matrix();
            pos2d = K * pos3d;
            points2d = pos2d(1:2, :) ./ repmat(pos2d(3, :), 2, 1);
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
