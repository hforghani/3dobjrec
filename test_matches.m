
clearvars; close all;

test_im_name = 'test.jpg';
matches_f_name = 'data/matches_anchiceratops';
model_f_name = 'data/model_anchiceratops_multi';
model_data_path = [get_dataset_path() '0-24(1)\0-24\anchiceratops\'];

matches = load(matches_f_name);
matches2d = matches.matches2d;
matches3d = matches.matches3d;
match_count = size(matches2d,2);

load(model_f_name);

%% Draw matches.
image = imread(test_im_name);
imshow(image);
figure(1);
hold on;
scatter(matches2d(1,:), matches2d(2,:), 'r', 'filled');

while 1
    %% Select point in matches.
    figure(1);
    [x,y] = ginput(1);
    min_dist = -1;
    sel_index = -1;
    for i = 1:match_count
        dist = norm(matches2d(:,i) - [x;y]);
        if min_dist == -1 || dist < min_dist
            min_dist = dist;
            sel_index = i;
            nearest_point = matches2d(:,i);
        end
    end
    scatter(nearest_point(1), nearest_point(2), 'gx');
    
    %% Show point in its camera view.
    point = matches3d{sel_index};
    point.show_measurements(model, model_data_path);
    reply = input('Do you want more? Y/N [Y]: ', 's');
    if isempty(reply)
        reply = 'Y';
    end
    if reply == 'N'
        break;
    end
end
