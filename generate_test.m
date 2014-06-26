close all;
addpath model;
addpath utils;

case_name = 'all18';
desc_model_f_name = ['data/model_desc/' case_name];
desc_model = load(desc_model_f_name);
obj_names = desc_model.obj_names;
clear desc_model;

plot_i = 1;

for i = 1:6
    obj_name = obj_names{randi(length(obj_names))};
    model_path = [get_dataset_path() '0-24(1)\0-24\' obj_name '\'];
    load (['data/model/' obj_name]);
    cam_index = randi(length(model.cameras));
    
    [trans_im, R, T] = apply_random_homo(model, model_path, cam_index);

    figure(1); subplot(2, 3, plot_i);
    imshow(uint8(trans_im), [0 255]);
    title(obj_name, 'interpreter', 'none');
    plot_i = plot_i + 1;
end
