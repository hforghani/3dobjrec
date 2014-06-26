function [trans_im, cam_R, cam_T] = apply_random_homo(model, model_path, cam_index)
    % Segment the object.
    cam = model.cameras{cam_index};
    im = cam.get_image(model_path);
    seg_im = segment_obj(im, model, cam_index);
    
    % Apply random translation along Z cooridnate.
    max_depth_mult = 1.5;
    depth_mult = rand * (max_depth_mult-1) + 1;
    res = imresize(seg_im, 1 / depth_mult);
    [xs, ys, ~] = size(res);
    [x, y, ~] = size(seg_im);
    top_x = floor((x-xs)/2);
    left_y = floor((y-ys)/2);
    seg_im = zeros(size(seg_im));
    seg_im(top_x : top_x+xs-1, left_y : left_y+ys-1, :) = res;

    % Create random rotation matrix.
    phi_z = rand * 2*pi - pi;
    R = rot_matrix([0 0 1], phi_z);
    phi_x = rand * 2*pi/8 - pi/8;
    R = R * rot_matrix([1 0 0], phi_x);
    phi_y = rand * 2*pi/10 - pi/10;
    R = R * rot_matrix([0 1 0], phi_y);
    R = R(1:3, 1:3);
    
    fprintf('phi_x = %f, phi_y = %f, phi_z = %f\n', phi_x, phi_y, phi_z);

    % Apply homography.
    K = model.calibration.get_calib_matrix();
    H = K * R / K;
    trans_im = imTransD(seg_im, H, [size(seg_im,1), size(seg_im,2)]);

    cam_T = cam.center * depth_mult;
    cam_R = cam.rotation_matrix() * R;
end

function im_seg = segment_obj(im, model, cam_index)
    cam = model.cameras{cam_index};
    R = cam.rotation_matrix();
    T = cam.center;
    points = model.trans_to_cam_coord(R, T);
    poses = model.calibration.get_calib_matrix() * points;
    poses = poses ./ repmat(poses(3,:), 3, 1);
    poses(3,:) = [];
    
    poses = filter_poses(poses);

    bw = true(size(im,1), size(im,2));
    rad = 20;
    shape_inserter = vision.ShapeInserter('Shape','Circles', 'Fill', true);
    pts = uint16([round(poses)', repmat(rad, size(poses,2), 1)]);
    bw = step(shape_inserter, bw, pts);
    bw = ~bw;
%     figure(1); subplot(2,2,1); imshow(bw);
    bw = bwmorph(double(bw), 'dilate', 5);
%     subplot(2,2,2); imshow(bw);
    bw = bwmorph(double(bw), 'thin', 17);
%     subplot(2,2,3); imshow(bw);
    im_seg = zeros(size(im));
    for c = 1:3
        ch = im(:,:,c); ch(~bw) = 0; im_seg(:,:,c) = ch;
    end
    im_seg = uint8(im_seg);
    
    % Add gray threshold segmentation result.
    level = 0.2;
    bw = im2bw(im, level);
%     figure; imshow(bw);
    for c = 1:3
        ch = im_seg(:,:,c); ch_im = im(:,:,c); ch(~bw) = ch_im(~bw); im_seg(:,:,c) = ch;
    end
%     subplot(2,2,4); imshow(im_seg);
end

function res = filter_poses(poses)
    nei_thr = 20;
    kdtree = vl_kdtreebuild(poses);
    [~, distances] = vl_kdtreequery(kdtree, poses, poses, 'NUMNEIGHBORS', 4);
    res = poses(:, distances(4,:) < nei_thr);
end
