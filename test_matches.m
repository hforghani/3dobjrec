clearvars; close all;

test_im_name = 'test.jpg';
matches_f_name = 'data/matches_anchiceratops';

matches = load(matches_f_name);
matches2d = matches.matches2d;
matches3d = matches.matches3d;
match_count = size(matches2d,2);

%% Draw matches.
image = imread(test_im_name);
imshow(image);
figure(1);
hold on;
scatter(matches2d(1,:), matches2d(2,:), 'r', 'filled');

%% Select point in matches.
while 1
    figure(1);
    [x,y] = ginput(1);
    min_dist = -1;
    for i = 1:match_count
        dist = norm(matches2d(:,i) - [x;y]);
        if min_dist == -1 || dist < min_dist
            min_dist = dist;
            nearest_point = matches2d(:,i);
        end
    end
    scatter(nearest_point(1), nearest_point(2), 'gx');
end

%% Show point in its camera view.

