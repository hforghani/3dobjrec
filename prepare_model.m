% You may run just once.
% run('VLFEATROOT/toolbox/vl_setup');

%% Read model
model_path = [get_dataset_path() '0-24(1)\0-24\anchiceratops\'];
model_fname = [model_path 'model.nvm'];
model = read_model(model_fname);
save model;

%% Offline model preparation
model = create_model_descriptors(model, model_path);
save model;
