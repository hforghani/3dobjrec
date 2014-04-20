close all;

% test_im_name = [get_dataset_path() '0-24(1)\0-24\anchiceratops\db_img\1090.jpg'];
test_im_name = [get_dataset_path() '0-24(1)/0-24/axe_knight/db_img/1090.jpg'];
% test_im_name = 'test/test3.jpg';

% obj_name = 'anchiceratops';
obj_name = 'axe_knight';

parts = textscan(test_im_name, '%s', 'delimiter', '/');
parts = textscan(parts{1}{end}, '%s', 'delimiter', '.');
exact_name = parts{1}{1};
matches_f_name = ['data/matches_' obj_name '_' exact_name];

model_f_name = ['data/model_' obj_name];

model_data_path = [get_dataset_path() '0-24(1)\0-24\' obj_name '\'];

matches = load(matches_f_name);
matches2d = matches.matches2d;
matches3d = matches.matches3d;
matches_dist = matches.matches_dist;
match_count = size(matches2d,2);

load(model_f_name);

%% Draw matches.
image = imread(test_im_name);
imshow(image);
figure(1);
hold on;
scatter(matches2d(1,:), matches2d(2,:), 'r', 'filled');
% for i = 1:match_count
%     text(matches2d(1,i), matches2d(2,i), num2str(i), 'Color', 'y');
% end

disp('Select a key point on the image.');
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
    sel_point_index = matches3d(1,sel_index);
    point = model.points{sel_point_index};
    point.show_measurements(model, model_data_path);
    fprintf('distance between 2d and 3d = %f\n', matches_dist(sel_index));
    reply = input('Do you want more? Y/N [Y]: ', 's');
    if reply == 'N'
        break;
    end
end
