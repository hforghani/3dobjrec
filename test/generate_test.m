close all;
addpath model;
addpath utils;

% Load object names.
case_name = 'all18';
desc_model_f_name = ['data/model_desc/' case_name];
desc_model = load(desc_model_f_name);
obj_names = desc_model.obj_names;
clear desc_model;

% Load test backgrounds.
bckg_path = 'test_img/background/';
backg_files = dir(bckg_path);
backg_files = backg_files(3:end);

% parameters:
TEST_COUNT = 1;
MAX_OBJ_PER_TEST = 4;
IMAGE_HEIGHT = 720;
IMAGE_WIDTH = 1280;
TEST_PATH = 'test_img/auto/';

% Count test images and open data file.
data_fname = [TEST_PATH 'data.txt'];
cur_test_count = numel(dir(TEST_PATH)) - 2;
if exist(data_fname, 'file') > 0
    cur_test_count = cur_test_count - 1;
end
fid = fopen(data_fname, 'a');

% Create tests.
for i = 1:TEST_COUNT
    fprintf('test number %d\n', i);
    
    % Read background image and initialize test image.
%     index = randi(numel(backg_files));
%     test_im = imread([bckg_path, backg_files(index).name]);
%     test_im = imresize(test_im, [IMAGE_HEIGHT, IMAGE_WIDTH]);
    test_im = uint8(ones(IMAGE_HEIGHT, IMAGE_WIDTH, 3)) * 255;
    
    test_obj_names = '';
    obj_count = randi(MAX_OBJ_PER_TEST);
    
    for j = 1:obj_count
        fprintf('\tobject %d\n', j);
        
        obj_name = obj_names{randi(length(obj_names))};
        test_obj_names = [test_obj_names ' ' obj_name];
        model_path = [get_dataset_path() '0-49\' obj_name '\'];
        load (['data/model/' obj_name]);
        cam_index = randi(length(model.cameras));

        % Create random depth multiplicant.
        max_depth_mult = 1.2;
        min_depth_mult = 0.8;
        depth_mult = rand * (max_depth_mult - min_depth_mult) + min_depth_mult;

        % Create random rotation matrix.
        phi_z = rand * 2*pi - pi;
        phi_x = rand * 2*pi/7 - pi/7;
        phi_y = rand * 2*pi/10 - pi/10;

        cam = model.cameras{cam_index};
        im = cam.get_image(model_path);
        [obj_im, bw, R, T] = apply_homo(model, im, depth_mult, phi_x, phi_y, phi_z);

        for c = 1:3
            ch_obj = obj_im(:,:,c); ch_test = test_im(:,:,c);
            ch_test(bw) = ch_obj(bw); test_im(:,:,c) = ch_test;
        end
    end
    
    cur_test_count = cur_test_count + 1;
    fname = [num2str(cur_test_count) '.jpg'];
    imwrite(test_im, [TEST_PATH fname]);
    fprintf(fid, '%s\n%d%s\n', fname, obj_count, test_obj_names);
end

fclose(fid);
