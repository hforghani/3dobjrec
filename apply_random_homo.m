function [trans_im, trans_bw, cam_R, cam_T] = apply_random_homo(model, model_path, cam_index)

    % Segment the object.
    cam = model.cameras{cam_index};
    im = cam.get_image(model_path);
    [seg_im, bw] = segment_obj(im, model, cam_index);
    
    % Create random depth multiplicant.
    max_depth_mult = 1.2;
    min_depth_mult = 0.8;
    depth_mult = rand * (max_depth_mult - min_depth_mult) + min_depth_mult;

    % Create random rotation matrix.
    phi_z = rand * 2*pi - pi;
    R = rot_matrix([0 0 1], phi_z);
    phi_x = rand * 2*pi/7 - pi/7;
    R = R * rot_matrix([1 0 0], phi_x);
    phi_y = rand * 2*pi/10 - pi/10;
    R = R * rot_matrix([0 1 0], phi_y);
    R = R(1:3, 1:3);
%     fprintf('phi_x = %f, phi_y = %f, phi_z = %f\n', phi_x, phi_y, phi_z);
    
    trans_im = apply_transform(seg_im, depth_mult, R, model.calibration);
    trans_bw = apply_transform(single(bw), depth_mult, R, model.calibration);
    trans_bw(isnan(trans_bw)) = 0;
    trans_bw = logical(trans_bw);

    cam_T = cam.center * depth_mult;
    cam_R = cam.rotation_matrix() * R;
end

function trans_im = apply_transform(im, depth_mult, R, cal)
    % Apply translation along Z then rotation and return camera image.
    % cal : calibration instance
    
    % Apply translation along Z cooridnate by depth multiplication.
    res = imresize(im, 1 / depth_mult);
    [xs, ys, ~] = size(res);
    [x, y, ~] = size(im);
    if xs < x
        top_x = ceil((x-xs)/2);
        left_y = ceil((y-ys)/2);
        trans_im = zeros(size(im));
        trans_im(top_x : top_x+xs-1, left_y : left_y+ys-1, :) = res;
    else
        top_x = ceil((xs-x)/2);
        left_y = ceil((ys-y)/2);
        trans_im = res(top_x : top_x+x-1, left_y : left_y+y-1, :);
    end
    
    % Apply homography by rotation matrix R.
    K = cal.get_calib_matrix();
    H = K * R / K;
    trans_im = imTransD(trans_im, H, [x, y]);
end

function [im_seg, bw] = segment_obj(im, model, cam_index)
    % Project points to camera image plane.
    cam = model.cameras{cam_index};
    R = cam.rotation_matrix();
    T = cam.center;
    points = model.trans_to_cam_coord(R, T);
    poses = model.calibration.get_calib_matrix() * points;
    poses = poses ./ repmat(poses(3,:), 3, 1);
    poses(3,:) = [];
    
    % Filter outlier points.
    poses = filter_poses(poses);

    % Segment points region.
    bw = true(size(im,1), size(im,2));
    rad = 20;
    shape_inserter = vision.ShapeInserter('Shape','Circles', 'Fill', true);
    pts = uint16([round(poses)', repmat(rad, size(poses,2), 1)]);
    bw = step(shape_inserter, bw, pts);
    bw = ~bw;
    bw = bwmorph(double(bw), 'dilate', 5);
    bw = bwmorph(double(bw), 'thin', 17);
    
    % Add gray threshold segmentation result.
    level = 0.3;
    bw = bw | ~im2bw(im, level);
    
    % Segment region of im specified by bw.
    im_seg = zeros(size(im));
    for c = 1:3
        ch = im(:,:,c); ch(~bw) = 0; im_seg(:,:,c) = ch;
    end
end

function res = filter_poses(poses)
    nei_thr = 20;
    kdtree = vl_kdtreebuild(poses);
    [~, distances] = vl_kdtreequery(kdtree, poses, poses, 'NUMNEIGHBORS', 4);
    res = poses(:, distances(4,:) < nei_thr);
end
