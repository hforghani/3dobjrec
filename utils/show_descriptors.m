function show_descriptors( image, frames )
% image: gray-scale image
% frames: descriptor frames

figure;
imshow(image, [0 255]);
hold on;

% Show some of features.
% perm = randperm(query_points_num);
% sel = perm(1:1000);
sel = 1:size(frames, 2);
h1 = vl_plotframe(frames(:,sel));
h2 = vl_plotframe(frames(:,sel));
set(h1,'color','k','linewidth',3);
set(h2,'color','y','linewidth',2);

end

