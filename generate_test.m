addpath model;
addpath utils;

obj_name = 'anchiceratops';
model_path = [get_dataset_path() '0-24(1)\0-24\' obj_name '\'];
load (['data/model/' obj_name]);

% Segment the object;
im = model.cameras{1}.get_image(model_path);
gray = rgb2gray(im);
level = graythresh(gray);
bw = im2bw(gray,level);
% imshow(bw);

plot_i = 1;

for i = -1:1:1
    for j = -1:1:1
        for k = -0.4:0.8:0.4
            %% Apply homography.
            R = rot_matrix([0,i,j], k);
            R = R(1:3, 1:3);
            K = model.calibration.get_calib_matrix();
            H = K * R / K;
            % tform = maketform('projective', H);
            % trans_im = imtransform(gray, tform);
            trans_im = imTransD(im, H, size(gray));
            trans_bw = imTransD(double(bw), H, size(gray));
            trans_bw(isnan(trans_bw)) = 255;
%             figure(1); imshow(trans_bw, [0 1]);

            %% Segment the object.
            seg_im = zeros(size(im));
            for c = 1:3
                col_chan = trans_im(:,:,c); col_chan(logical(trans_bw)) = 255; seg_im(:,:,c) = col_chan;
            end
            subplot(3, 6, plot_i);
%             figure(2);
            imshow(uint8(seg_im), [0 255]);
            plot_i = plot_i + 1;
        end
    end
end
